-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_import_lines AS

  PROCEDURE import_lines(p_batch_id IN NUMBER) IS
    v_skipped PLS_INTEGER := 0;
  BEGIN
    FOR l IN (SELECT line_id FROM import_line WHERE batch_id = p_batch_id) LOOP
      BEGIN
        pkg_import_api.apply_line(l.line_id);
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          v_skipped := v_skipped + 1;
          COMMIT; -- expect: PLL003
      END;
    END LOOP;
    pkg_import_api.report_skipped(p_batch_id, v_skipped);
  END import_lines;

  PROCEDURE import_headers(p_batch_id IN NUMBER) IS
  BEGIN
    FOR h IN (SELECT header_id FROM import_header WHERE batch_id = p_batch_id) LOOP
      BEGIN
        pkg_import_api.apply_header(h.header_id);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          ROLLBACK; -- expect: PLL003
      END;
    END LOOP;
  END import_headers;

END pkg_import_lines;
/
