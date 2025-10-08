CREATE TABLE current_notebook_id(id UUID NOT NULL);;
CREATE TABLE has_onboarded(has_onboarded BOOLEAN);;
CREATE TABLE notebooks(id UUID PRIMARY KEY, "name" VARCHAR NOT NULL, created TIMESTAMP NOT NULL);;
CREATE TABLE notebook_versions(notebook_id UUID, "version" INTEGER, title VARCHAR NOT NULL, "json" VARCHAR NOT NULL, created TIMESTAMP NOT NULL, expires TIMESTAMP, PRIMARY KEY(notebook_id, "version"));;

