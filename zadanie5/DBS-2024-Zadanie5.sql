-- Drop dependent tables first
DROP TABLE IF EXISTS exhibition_exemplar CASCADE;
DROP TABLE IF EXISTS lent_exemplars;
DROP TABLE IF EXISTS exhibitions;
DROP TABLE IF EXISTS exemplars;

DROP TABLE IF EXISTS categories;

DROP TABLE IF EXISTS institutions;
DROP TABLE IF EXISTS zones;

-- Drop types
DROP TYPE IF EXISTS exhibition_status;
DROP TYPE IF EXISTS institution_type;
DROP TYPE IF EXISTS location_status;

CREATE TYPE "location_status" AS ENUM (
  'on_way_to_owner',
  'on_way_to_borrower',
  'in_our_warehouse',
  'in_other_warehouse',
  'is_exhibited'
);

CREATE TYPE "institution_type" AS ENUM (
  'our_museum',
  'other_museum',
  'private_collector',
  'institution'
);

CREATE TYPE "exhibition_status" AS ENUM (
  'closed',
  'preparing',
  'ongoing'
);

CREATE TABLE "institutions" (
  "id" SERIAL PRIMARY KEY,
  "type" institution_type NOT NULL,
  "name" VARCHAR(50) UNIQUE NOT NULL,
  "creation_date" TIMESTAMPTZ NOT NULL
);

CREATE TABLE "exemplars" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(100) UNIQUE NOT NULL,
  "location_status" location_status NOT NULL DEFAULT 'in_our_warehouse',
  "owner_id" INT NOT NULL,
  "category" INT NOT NULL,
  "collected_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "lent_exemplars" (
  "id" SERIAL PRIMARY KEY,
  "owner" INT NOT NULL,
  "lent_to" INT NOT NULL,
  "exemplar_id" INT NOT NULL,
  "lent_from" TIMESTAMPTZ NOT NULL,
  "expected_return" DATE NOT NULL,
  "not_lent_anymore" BOOLEAN NOT NULL,
  "validation_started" TIMESTAMPTZ,
  "validation_ended" TIMESTAMPTZ,
  "validated" BOOLEAN
);

CREATE TABLE "categories" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE "exhibitions" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(50) NOT NULL,
  "exhibited_by" INT NOT NULL,
  "start_time" TIMESTAMPTZ NOT NULL,
  "end_time" TIMESTAMPTZ NOT NULL,
  "status" exhibition_status NOT NULL DEFAULT 'preparing'
);

CREATE TABLE "zones" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE "exhibition_exemplar" (
  "exhibition_id" INT NOT NULL,
  "exemplar_id" INT NOT NULL,
  "zone_id" INT NOT NULL
);

ALTER TABLE "lent_exemplars" ADD FOREIGN KEY ("owner") REFERENCES "institutions" ("id");

ALTER TABLE "lent_exemplars" ADD FOREIGN KEY ("lent_to") REFERENCES "institutions" ("id");

ALTER TABLE "lent_exemplars" ADD FOREIGN KEY ("exemplar_id") REFERENCES "exemplars" ("id");

ALTER TABLE "exemplars" ADD FOREIGN KEY ("owner_id") REFERENCES "institutions" ("id");

ALTER TABLE "exemplars" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id");

ALTER TABLE "exhibitions" ADD FOREIGN KEY ("exhibited_by") REFERENCES "institutions" ("id");

ALTER TABLE "exhibition_exemplar" ADD FOREIGN KEY ("exemplar_id") REFERENCES "exemplars" ("id");

ALTER TABLE "exhibition_exemplar" ADD FOREIGN KEY ("exhibition_id") REFERENCES "exhibitions" ("id");

ALTER TABLE "exhibition_exemplar" ADD FOREIGN KEY ("zone_id") REFERENCES "zones" ("id");
