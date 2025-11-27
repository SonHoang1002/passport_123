String generateMimeType(int indexImageFormat) {
  String mimeType;
  switch (indexImageFormat) {
    case 0:
      mimeType = "image/jpeg";
      break;
    case 1:
      mimeType = "image/png";
      break;
    default:
      mimeType = "application/pdf";
      break;
  }
  return mimeType;
}
