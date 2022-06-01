FROM postgres:14.3

# Set environment variables
ENV POSTGRES_USER MeLi
ENV POSTGRES_PASSWORD MeLi
ENV POSTGRES_DB MeLi

# Set port
EXPOSE 5432

# Copy necessary files
COPY init_db.sql /docker-entrypoint-initdb.d/
COPY dataset.csv /temp/

#  This regex is to delete the empty rows
RUN sed -i '/^$/d' temp/dataset.csv 