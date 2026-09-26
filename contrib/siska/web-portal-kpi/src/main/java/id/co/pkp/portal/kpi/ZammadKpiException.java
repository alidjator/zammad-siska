package id.co.pkp.portal.kpi;

/** Zammad tidak bisa dihubungi / menolak request (token salah = 401/403, filter salah = 422). */
public class ZammadKpiException extends RuntimeException {

  private final int status;

  public ZammadKpiException(String message, int status, Throwable cause) {
    super(message, cause);
    this.status = status;
  }

  /** HTTP status dari Zammad, 0 kalau tidak sampai (timeout / koneksi). */
  public int status() {
    return status;
  }
}
