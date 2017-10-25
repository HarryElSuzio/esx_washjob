INSERT INTO `addon_account` (name, label, shared) VALUES
  ('society_wash','Wash',1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
  ('society_wash','Wash',1)
;

INSERT INTO `jobs` (name, label) VALUES
  ('wash','Blanchisseur')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  ('wash',0,'recrue','Recrue',0,'{}','{}'),
  ('wash',1,'novice','à domicile',0,'{}','{}'),
  ('wash',4,'boss','Patron',0,'{}','{}')
;
