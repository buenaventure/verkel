# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

`sudo -u postgres createuser -P project_name``
-> enter db password
`sudo -u postgres createdb -O project_name project_name``
Add to `/etc/postgresql/14/main/pg_hba.conf``
> host	project_name	project_name	172.17.0.1/16	md5

`docker exec -it verkel_project_name bundle exec rails db:migrate`
`docker exec -it verkel_project_name bundle exec rails hunger_factor:import`
`docker exec -it verkel_project_name bundle exec rails c`
-> `User.create(email: 'your.email@example.com', password: 's3cr3tpwd', role: :admin)`
-> `GroupBoxIngredientUnitCache.do_calculate`