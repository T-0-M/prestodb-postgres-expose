FROM python:3.6-slim
LABEL description="This Dockerfile run SmartSteps Insight Portal service"
ENV PYTHONUNBUFFERED 1

# ca-certifies for install artifactory cert
# gcc to compile some python and mysql libs
# curl to download certs
# git to install libraries than are actually on github/pdihub
# default-libmysqlclient-dev mysql headers
RUN apt-get update && \
    apt-get install -y ca-certificates \
    gcc \
    curl \
    libpcre3 \
    libpcre3-dev \
    mime-support \
    uwsgi \
    default-libmysqlclient-dev

# In order to install from artifactory
# RUN curl -k  -o /etc/ssl/certs/ISSUECATID_bundle_2016-2030.cer https://artifactory.hi.inet/artifactory/yum-eng-dsn/TID-CA/ISSUECATID_bundle_2016-2030.cer && \
#    update-ca-certificates

# Allows docker to cache installed dependencies between builds
COPY requirements/ /tmp/
RUN pip install --no-cache-dir -r /tmp/prod.txt

RUN groupadd -g 501 ip && \
    useradd -u 501 -g ip ip

# Adds our application code to the image
COPY ./insights_portal_backend /app/insights_portal_backend/
COPY ./config /app/config/
COPY ./manage.py app
COPY ./startserver_dev_uwsgi.sh app
COPY ./VERSION app
COPY ./insights_portal_backend/assets  /app/insights_portal_backend/assets/

RUN chmod +x /app/startserver_dev_uwsgi.sh && \
    chown -R ip:ip /app

WORKDIR app
USER ip:ip
EXPOSE 4444

# Migrates the database, uploads staticfiles, and runs the production server
# This COULD be moved to a post_install phase
#CMD ./manage.py migrate && \
#    ./manage.py collectstatic --noinput && \
#    gunicorn --bind 0.0.0.0:$PORT --access-logfile - insights_portal_backend.wsgi:application

CMD ["/bin/sh", "-c", ". /app/config/dev_envSSIP && \
                         ls -la && \
                         python /app/manage.py migrate && \
                         sed -i s@API_URL@$API_URL@g /app/insights_portal_backend/assets/main.js && \
                         /app/startserver_dev_uwsgi.sh"]
