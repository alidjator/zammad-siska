package id.co.pkp.portal.kpi.dto;

/** Hasil GET /api/v1/team_kpi/export (.xlsx). */
public record ExportFile(String filename, byte[] content) {

  public static final String CONTENT_TYPE =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
}
