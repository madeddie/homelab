FROM jellyfin/jellyfin:10.10.7

ARG JELLYFIN_WEB_ROOT="/jellyfin/jellyfin-web"

COPY ./add-oauth-button.js ${JELLYFIN_WEB_ROOT}/add-oauth-button.js

RUN sed -i '0,/<head>/s|<head>|<head><script type="text/javascript" src="add-oauth-button.js"></script>|' ${JELLYFIN_WEB_ROOT}/index.html
