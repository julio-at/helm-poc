FROM nginx:alpine

# Borra el contenido por defecto de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia tu landing
COPY index.html /usr/share/nginx/html/index.html

# (Opcional) copiar carpeta de imágenes si la tienes
COPY img/ /usr/share/nginx/html/img/

RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

