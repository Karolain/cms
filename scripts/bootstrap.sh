#!/usr/bin/env bash
# Setup locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install dependencies
apt-get update
apt-get install -y python3 python3-dev postgresql libpq-dev nginx make git libjpeg-dev libxml2-dev libxslt1-dev screen curl dos2unix nginx
curl -sL https://deb.nodesource.com/setup_5.x | bash -
apt-get install -y nodejs

# Update and install global node packages
npm install -g npm
npm install -g gulp bower

# Prepare database
su -c "createuser -s root" postgres
su -c "createdb -O root root" postgres
createuser -s vagrant
createdb -O vagrant vagrant
psql -c "CREATE USER asmweb WITH PASSWORD 'asmweb';"
createdb asmweb -O asmweb -E utf8 -l en_US.utf8 -T template0

# Install Python 3.5 if not already installed
if ! [ -d /opt/python3.5 ]; then
    wget https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tar.xz
    tar xfvJ Python-3.5.1.tar.xz
    cd Python-3.5.1
    ./configure --prefix=/opt/python3.5
    make
    make install
    ln -fs /opt/python3.5/bin/python3 /usr/bin/python3
    ln -fs /opt/python3.5/bin/pip3 /usr/bin/pip3
    ln -fs /opt/python3.5/bin/pyvenv /usr/bin/pyvenv
    cd ..
    rm -rf Python-3.5.1
    rm Python-3.5.1.tar.xz
fi

# Create pyvenv if not already created
if ! [ -d /home/vagrant/env ]; then
    sudo -u vagrant pyvenv /home/vagrant/env
fi

# Setup scripts
chmod +x /vagrant/scripts/update-venv.sh
chmod +x /vagrant/scripts/gulp.sh
chmod +x /vagrant/scripts/django.sh
chmod +x /vagrant/scripts/run-dev.sh
chmod +x /vagrant/scripts/import-database.sh
dos2unix /vagrant/scripts/*.sh
ln -fs /vagrant/scripts/run-dev.sh /home/vagrant
ln -fs /vagrant/scripts/gulp.sh /home/vagrant
ln -fs /vagrant/scripts/django.sh /home/vagrant
ln -fs /vagrant/scripts/import-database.sh /home/vagrant
ln -fs /vagrant/scripts/update-venv.sh /home/vagrant

# Copy template as local.py
cp /vagrant/assembly/settings/local.py.template /vagrant/assembly/settings/local.py

# Install frontend dependencies
cd /vagrant/frontend
npm install --upgrade --no-bin-links
gulp build

# Setup pyvenv
/vagrant/scripts/update-venv.sh

# Create super user
cd /vagrant
source /home/vagrant/env/bin/activate
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@dev.assembly.org', 'admin')" | python manage.py shell
deactivate

# Setup and start nginx
ln -fs /vagrant/config/nginx.conf /etc/nginx/nginx.conf
/etc/init.d/nginx restart

# Chown all the things
chown -R vagrant:vagrant /vagrant
chown -R vagrant:vagrant /home/vagrant

