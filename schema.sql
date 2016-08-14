CREATE TABLE lists (
	id serial PRIMARY KEY,
	name text NOT NULL UNIQUE
);

CREATE TABLE todos (
	id serial PRIMARY KEY,
	name text NOT NULL,
	complete boolean NOT NULL DEFAULT false,
	list_id integer NOT NULL REFERENCES lists (id)
);

