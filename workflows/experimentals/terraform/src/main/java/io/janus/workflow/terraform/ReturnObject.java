package io.janus.workflow.terraform;

public class ReturnObject {
  private int returnCode;
  private String errorMessage;

  public ReturnObject(int returnCode, String errorMessage) {
    this.returnCode = returnCode;
    this.errorMessage = (errorMessage != null) ? errorMessage : "";
  }

  public ReturnObject(int returnCode) {
    this.returnCode = returnCode;
    this.errorMessage = "";
  }

  public int getReturnCode() {
    return this.returnCode;
  }

  public String getErrorMessage() {
    return this.errorMessage;
  }

  public void setReturnCode(int returnCode) {
    this.returnCode = returnCode;
  }

  public void setErrorMessage(String errorMessage) {
    this.errorMessage = errorMessage;
  }

  @Override
  public String toString() {
    return "ReturnObject [returnCode=" + returnCode + ", errorMessage=" + errorMessage + "]";
  }

}
