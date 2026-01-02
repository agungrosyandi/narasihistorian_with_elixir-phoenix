.PHONY: help setup install start server test test.watch format check deps clean db.create db.migrate db.rollback db.reset db.seed routes

# Default target
help:
	@echo "Available commands:"
	@echo "  make setup        						- Initial project setup (install deps + setup db)"
	@echo "  make install      						- Install dependencies"
	@echo "  make start        						- Start Phoenix server"
	@echo "  make server       						- Start Phoenix server (alias)"
	@echo "  make test         						- Run tests"
	@echo "  make test.watch   						- Run tests in watch mode"
	@echo "  make format       						- Format code"
	@echo "  make check        						- Check code formatting"
	@echo "  make deps         						- Get and compile dependencies"
	@echo "  make clean        						- Clean build artifacts"
	@echo "  make db.create    						- Create database"
	@echo "  make db.migrate   						- Run migrations"
	@echo "  make db.rollback  						- Rollback last migration"
	@echo "  make db.status.migration  					- Check status migrations"
	@echo "  make db.reset     						- Drop, create, and migrate database"
	@echo "  make db.seed      						- Seed database"
	@echo "  make routes       						- Show all routes"
	@echo "  make crud.custom.migrate    					- Create custom migration"
	@echo "  make crud.embedded   						- create Schema only"
	@echo "  make crud.schema    						- create Schema and Migration"
	@echo "  make crud.context    				           	- create Schema, Migration, and Context"
	@echo "  make crud.live    						- create Schema, Migration, Context, and LiveView"
	@echo "  make crud.json    						- Create Schema, Migration, Context, Controller, and View"
	@echo "  make crud.html    						- Create Schema, Migration, Context, Controller, and View"
	@echo "  make auth    							- Create auth generator"

crud.info:
	@echo ""
	@echo "CRUD Generator Usage Examples:"
	@echo ""
	@echo "1. Embedded Schema (no database table):"
	@echo "   make crud.embedded Accounts.User.Address addresses street:string city:string"
	@echo ""
	@echo "2. Schema + Migration:"
	@echo "   make crud.schema Accounts.User users name:string email:string:unique age:integer"
	@echo ""
	@echo "3. Context (Schema + Migration + Context functions):"
	@echo "   make crud.context Accounts User users name:string email:string:unique"
	@echo ""
	@echo "4. LiveView (Full CRUD with LiveView UI):"
	@echo "   make crud.live Charities Charity charities name:string:unique slug:string:unique"
	@echo ""
	@echo "5. JSON API (Full CRUD with JSON endpoints):"
	@echo "   make crud.json Accounts User users name:string email:string:unique"
	@echo ""
	@echo "6. HTML (Full CRUD with traditional HTML views):"
	@echo "   make crud.html Blog Post posts title:string body:text published:boolean"
	@echo ""
	@echo "Field types: string, text, integer, float, decimal, boolean, date, time, datetime, uuid, references"
	@echo "Modifiers: :unique, :required, :redact"
	@echo ""


# Initial setup

setup: install db.create db.migrate
	@echo "✓ Setup complete!"

# Install dependencies

install:
	mix deps.get
	cd assets && npm install

# Start server

start:
	mix phx.server

server: start

# Interactive shell with server

shell:
	iex -S mix phx.server

# Run tests

test:
	mix test

# Run tests in watch mode

test.watch:
	mix test.watch

# Format code

format:
	mix format

# Check formatting

check:
	mix format --check-formatted

# Get and compile dependencies

deps:
	mix deps.get
	mix deps.compile

# Clean build artifacts

clean:
	mix clean
	rm -rf _build deps

# Database commands

db.create:
	mix ecto.create

db.migrate:
	mix ecto.migrate

db.status.migration:
	mix ecto.migrations

db.rollback:
	mix ecto.rollback

db.reset:
	mix ecto.reset

db.seed:
	mix run priv/repo/seeds.exs

# Show routes

routes:
	mix phx.routes

# Compile

compile:
	mix compile

# Run dialyzer for type checking

dialyzer:
	mix dialyzer

# Generate docs

docs:
	mix docs

# CRUD generator docs

# crud.info:
# 	mix help phx.gen

crud.custom.migrate:
	mix ecto.gen.migration $(filter-out $@,$(MAKECMDGOALS))

crud.embedded:
	mix phx.gen.embedded $(filter-out $@,$(MAKECMDGOALS))

crud.schema:
	mix phx.gen.schema $(filter-out $@,$(MAKECMDGOALS))

crud.context:
	mix phx.gen.context $(filter-out $@,$(MAKECMDGOALS))

crud.live:
	mix phx.gen.live $(filter-out $@,$(MAKECMDGOALS))

crud.json:
	mix phx.gen.json $(filter-out $@,$(MAKECMDGOALS))

crud.html:
	mix phx.gen.html $(filter-out $@,$(MAKECMDGOALS))

# AUTH GENERATOR

auth:
	mix phx.gen.auth $(filter-out $@,$(MAKECMDGOALS))

# Catch-all rule to prevent make from complaining about unknown targets

%:
	@:

# Assets commands

assets.build:
	cd assets && npm run build

assets.deploy:
	cd assets && npm run deploy
