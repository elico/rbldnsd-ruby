all:
	ehco OK

install:
	mkdir -p /usr/local/rbldnsd-rb
	mkdir -p /var/rbldnsd/db
	cp -v {rbldnsd.rb,load-lists.rb} /usr/local/rbldnsd-rb/


install-dependencies:
	dnf install -y ruby ruby-devel rubygem-json
	dnf group install -y "Development Tools"
	dnf module enable mariadb:10.5 -y
	dnf install mariadb-devel mariadb
	gem install bundler
	bundle install

install-service:
	cp -v service/rbldnsd-rb.service /etc/systemd/system/

enable-service:
	systemctl daemon-reload
	systemctl enable rbldnsd-rb.service
start: start-service

start-service:
	systemctl daemon-reload
	systemctl start rbldnsd-rb.service

stop: stop-service

stop-service:
	systemctl daemon-reload
	systemctl stop rbldnsd-rb.service

restart: stop start
