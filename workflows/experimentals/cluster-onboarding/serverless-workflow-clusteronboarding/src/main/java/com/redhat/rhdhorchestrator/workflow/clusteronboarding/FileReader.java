package com.redhat.rhdhorchestrator.workflow.clusteronboarding;


import jakarta.enterprise.context.ApplicationScoped;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;


@ApplicationScoped
public class FileReader {
    public Map<String, String> readValue(String filePath, String fieldName) throws IOException {
        return Map.of(fieldName, new String(Files.readAllBytes(Paths.get(filePath))));
    }
}
