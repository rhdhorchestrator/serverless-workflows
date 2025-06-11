package io.janus.workflow.terraform;

import jakarta.enterprise.context.ApplicationScoped;

import java.io.InputStream;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URL;
import java.net.HttpURLConnection;
import java.net.http.HttpClient;
import java.net.URI;
import java.io.OutputStream;

@ApplicationScoped
public class HandleTerraformConfigUpload {
    public ReturnObject UploadTerraformConfig(String tarArchiveSourceURL, String targetURLString) {

        try {
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder().uri(URI.create(tarArchiveSourceURL)).GET().build();
            HttpResponse<InputStream> response = client.send(request, HttpResponse.BodyHandlers.ofInputStream());

            URL targetURL = new URI(targetURLString).toURL();
            HttpURLConnection connection = (HttpURLConnection) targetURL.openConnection();
            connection.setDoOutput(true);
            connection.setRequestMethod("PUT");
            connection.setRequestProperty("Content-Type", "application/octet-stream");

            try (InputStream inputStream = response.body();
                    OutputStream outputStream = connection.getOutputStream()) {
                byte[] buffer = new byte[8192]; // 8KG, average tar file
                int bytesRead;

                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }
            } catch (Exception e) {
                e.printStackTrace();
                ReturnObject returnObject = new ReturnObject(connection.getResponseCode());
                if (connection.getErrorStream() != null) {
                    returnObject.setErrorMessage(connection.getErrorStream().toString());
                }
                connection.disconnect();
                return returnObject;
            }

            ReturnObject returnObject = new ReturnObject(connection.getResponseCode());
            if (connection.getErrorStream() != null) {
                returnObject.setErrorMessage(connection.getErrorStream().toString());
            }
            connection.disconnect();
            return returnObject;

        } catch (Exception e) {
            e.printStackTrace();
            return new ReturnObject(-1, "error unrelated to HTTP connection");
        }
    }
}