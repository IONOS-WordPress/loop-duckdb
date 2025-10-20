#!/usr/bin/env bash

#
# generates markdown output for user login related report part
# 

readonly LOGINS_PER_USER_DDL="
CREATE OR REPLACE TABLE logins_per_user (
  login_type VARCHAR, -- 'sso', 'manual' for now
  login_date VARCHAR,
  file VARCHAR,
  file_date TIMESTAMP,
  \"timestamp\" TIMESTAMP,
  instance VARCHAR
);

-- BEGIN TRANSACTION;
INSERT INTO logins_per_user VALUES
-- 1
  ('sso', now(), '/local/s3/2023-11-14/0010636d-e54d-45d2-9773-e8cb4adca4e7.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0010636d-e54d-45d2-9773-e8cb4adca4e7'),
  ('sso', now(), '/local/s3/2023-11-14/0010636d-e54d-45d2-9773-e8cb4adca4e7.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0010636d-e54d-45d2-9773-e8cb4adca4e7'),
  ('sso', now(), '/local/s3/2023-11-14/0010636d-e54d-45d2-9773-e8cb4adca4e7.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0010636d-e54d-45d2-9773-e8cb4adca4e7'),
  ('sso', now(), '/local/s3/2023-11-14/0010636d-e54d-45d2-9773-e8cb4adca4e7.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0010636d-e54d-45d2-9773-e8cb4adca4e7'),
  ('manual', now(), '/local/s3/2023-11-14/0010636d-e54d-45d2-9773-e8cb4adca4e7.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0010636d-e54d-45d2-9773-e8cb4adca4e7'),
-- 2  
  ('sso', now(), '/local/s3/2023-11-14/00315901-355e-426f-8e20-ee203f90f692.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00315901-355e-426f-8e20-ee203f90f692'),
  ('manual', now(), '/local/s3/2023-11-14/00315901-355e-426f-8e20-ee203f90f692.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00315901-355e-426f-8e20-ee203f90f692'),
  ('manual', now(), '/local/s3/2023-11-14/00315901-355e-426f-8e20-ee203f90f692.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00315901-355e-426f-8e20-ee203f90f692'),
  ('manual', now(), '/local/s3/2023-11-14/00315901-355e-426f-8e20-ee203f90f692.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00315901-355e-426f-8e20-ee203f90f692'),
  ('manual', now(), '/local/s3/2023-11-14/00315901-355e-426f-8e20-ee203f90f692.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00315901-355e-426f-8e20-ee203f90f692'),
  ('manual', now(), '/local/s3/2023-11-14/00315901-355e-426f-8e20-ee203f90f692.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00315901-355e-426f-8e20-ee203f90f692'),
-- 3  
  ('sso', now(), '/local/s3/2023-11-14/0058172b-4213-4fe4-ad66-d0fda327e247.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0058172b-4213-4fe4-ad66-d0fda327e247'),
-- 4
  ('sso', now(), '/local/s3/2023-11-14/0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe'),
  ('sso', now(), '/local/s3/2023-11-14/0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe'),
  ('manual', now(), '/local/s3/2023-11-14/0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe'),
  ('manual', now(), '/local/s3/2023-11-14/0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe'),
  ('sso', now(), '/local/s3/2023-11-14/0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0088a062-a92d-4a8f-bdc0-0afbd0ca5ffe'),
-- 5  
  ('sso', now(), '/local/s3/2023-11-14/00b31741-afc7-43f5-887a-464000258651.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00b31741-afc7-43f5-887a-464000258651'),
  ('sso', now(), '/local/s3/2023-11-14/00b31741-afc7-43f5-887a-464000258651.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00b31741-afc7-43f5-887a-464000258651'),
  ('manual', now(), '/local/s3/2023-11-14/00b31741-afc7-43f5-887a-464000258651.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00b31741-afc7-43f5-887a-464000258651'),
  ('manual', now(), '/local/s3/2023-11-14/00b31741-afc7-43f5-887a-464000258651.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00b31741-afc7-43f5-887a-464000258651'),
  ('manual', now(), '/local/s3/2023-11-14/00b31741-afc7-43f5-887a-464000258651.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00b31741-afc7-43f5-887a-464000258651'),
  ('manual', now(), '/local/s3/2023-11-14/00b31741-afc7-43f5-887a-464000258651.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00b31741-afc7-43f5-887a-464000258651'),
-- 6  
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
  ('manual', now(), '/local/s3/2023-11-14/00d15a89-3c5b-4c02-8b59-a66a9676525b.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '00d15a89-3c5b-4c02-8b59-a66a9676525b'),
-- 7  
  ('manual', now(), '/local/s3/2023-11-14/012dafba-07c4-4972-89eb-b646c7f3177d.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '012dafba-07c4-4972-89eb-b646c7f3177d'),
-- 8  
  ('manual', now(), '/local/s3/2023-11-14/0157c39b-b321-4090-b27f-6bfb820894df.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0157c39b-b321-4090-b27f-6bfb820894df'),
  ('sso', now(), '/local/s3/2023-11-14/0157c39b-b321-4090-b27f-6bfb820894df.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '0157c39b-b321-4090-b27f-6bfb820894df'),
-- 9  
  ('manual', now(), '/local/s3/2023-11-14/015ef223-ffe9-4836-a37a-96bdc3e80e9c.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '015ef223-ffe9-4836-a37a-96bdc3e80e9c'),
-- 10  
  ('sso', now(), '/local/s3/2023-11-14/016ed45f-7e67-4b72-95fc-df7920251276.json','2023-11-14 00:00:00', '2023-11-14 00:00:00', '016ed45f-7e67-4b72-95fc-df7920251276')
  ;
-- COMMIT TRANSACTION;
"

query_duckdb "$LOGINS_PER_USER_DDL;"

SQL="
-- [real insight]
-- how does users login - sso vs manual login
--

SELECT
    CAST(login_date AS DATE) AS login_day,
    login_type,
    COUNT(*) AS total_logins
  FROM logins_per_user
  GROUP BY 1, 2 -- Group by login_day, login_type
  ORDER BY login_day DESC, total_logins DESC;
"

TITLE="How do users login ?"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(query_duckdb "$SQL;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"\(.login_type)\" : \(.total_logins)")
')
\`\`\`
EOF

# ---

SQL="
-- [real insight]
-- active customers per week
--

SELECT
    CAST(login_date AS DATE) AS login_day,
    COUNT(*) FILTER (WHERE login_type = 'sso') AS sso_logins,
    COUNT(*) FILTER (WHERE login_type = 'manual') AS manual_logins,
    COUNT(*)+24 AS all_users
  FROM logins_per_user
  GROUP BY 1
  ORDER BY login_day DESC;
"

TITLE="Active customers per week"

cat <<EOF

# $TITLE

\`\`\`mermaid
$(echo $(query_duckdb "$SQL;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData title \($title)" ,
    (.[] | "  \"sso\" : \(.sso_logins)"),
    (.[] | "  \"manual\" : \( .manual_logins )"),
    (.[] | "  \"not logged in\" : \( .all_users - (.sso_logins + .manual_logins) )")
')
\`\`\`
EOF

# ---

SQL="
-- [real insight]
-- how do users login ? - sso, manual or using both login types ?
--

WITH UserLoginTypes AS (
  -- Step 1: Determine the distinct login types used by each user
  SELECT
    instance as user_id,
    -- Check if the user has *ever* used 'manual'
    BOOL_OR(login_type = 'manual') AS used_manual,
    -- Check if the user has *ever* used 'sso'
    BOOL_OR(login_type = 'sso') AS used_sso
  FROM logins_per_user
  GROUP BY 1
)
  -- Step 2: Categorize and count the users
  SELECT
    -- The CASE statement assigns a category to each user
    CASE
      WHEN used_manual AND NOT used_sso THEN 'only manual'
      WHEN used_sso AND NOT used_manual THEN 'only sso'
      WHEN used_sso AND used_manual THEN 'mixed (both sso and manual)'
      -- This final ELSE is good practice, though unlikely given the current data
      ELSE 'Other/Unknown'
    END AS login_behavior,
    COUNT(user_id) AS count_of_users
  FROM UserLoginTypes
  GROUP BY 1
  ORDER BY count_of_users DESC;
"

TITLE="How do users log in ?"

cat <<EOF

# $TITLE

> sso, manual or mixing both login types

\`\`\`mermaid
$(echo $(query_duckdb "$SQL;" '-json') | jq -r --arg title "$TITLE" '
    "pie showData" ,
    (.[] | "  \"\(.login_behavior)\" : \(.count_of_users)")
')
\`\`\`
EOF
