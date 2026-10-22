-- Written for this repo. Package spec with overloads, defaults and a forward declaration.
CREATE OR REPLACE PACKAGE shop AUTHID DEFINER AS
  c_max CONSTANT NUMBER := 10;
  TYPE t_rec IS RECORD (id NUMBER, name VARCHAR2(30));

  PROCEDURE add_item(p_id IN NUMBER, p_qty IN OUT NOCOPY NUMBER DEFAULT 1, p_note OUT VARCHAR2);
  FUNCTION total(p_order NUMBER) RETURN NUMBER;
  FUNCTION total(p_order NUMBER, p_tax NUMBER) RETURN NUMBER DETERMINISTIC;
END shop;
/
