FROM gcr.io/google_appengine/base

# Install Python and C dev libraries necessary to compile the most popular
# Python libraries.
RUN apt-get -q update && \
  apt-get install --no-install-recommends -y -q \
    build-essential python2.7 python2.7-dev python-setuptools \
    git mercurial libffi-dev libssl-dev libxml2-dev \
    libxslt1-dev libpq-dev libmysqlclient-dev libcurl4-openssl-dev \
    libjpeg-dev zlib1g-dev libpng12-dev && \
  apt-get clean && rm /var/lib/apt/lists/*_*

# This step adds the actual compiled runtime ('python setup.py sdist') to the
# docker image.
COPY python-runtime.tar.gz /home/vmagent/python-runtime.tar.gz

RUN easy_install pip
RUN pip install --upgrade gunicorn==19.4.1 futures==3.0.3
RUN pip install /home/vmagent/python-runtime.tar.gz

EXPOSE 8080

RUN ln -s /home/vmagent/app /app
WORKDIR /app

# Add the default gunicorn configuration file to the app directory. This
# default file will be overridden if the user adds a file called
# "gunicorn.conf.py" to their app's root directory.
ADD gunicorn.conf.py /app/gunicorn.conf.py

# Configure the entrypoint with Managed VMs-essential configuration like "bind",
# but leave the rest up to the config file.
ENTRYPOINT ["/usr/bin/env", "gunicorn", "-b", "0.0.0.0:8080", "google.appengine.vmruntime.wsgi:meta_app", "--log-file=-", "-c", "gunicorn.conf.py"]
