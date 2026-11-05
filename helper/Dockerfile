FROM python:3.14-trixie
RUN apt-get update && apt-get install -y imagemagick inkscape
RUN pip3 install icnsutil Pillow
COPY batch_export_icons.sh /
WORKDIR /home
CMD ["Icon_template.svg", "test"]
ENTRYPOINT ["/batch_export_icons.sh"]