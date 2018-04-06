FROM alpine/git as source

ARG BRANCH=master
WORKDIR /app

RUN git clone https://github.com/kubernetes/website && cd website && git checkout ${BRANCH}

RUN sed -i '/{% include header.html %}/d;/{% include_cached footer.html %}/d;/{% include footer-scripts.html %}/d;/^<!--  HERO  -->/,/^<\/section>/d;s/<div id="docsToc">/<div id="docsToc" style="display: none;">/g;/editPageButton/d;s/<div id="docsContent">/<div id="docsContent" style="width: 100%;">/g;/<p><a href=""><img src="https:\/\/kubernetes-site/,/{% endif %}/d' /app/website/_layouts/docwithnav.html

FROM jekyll/jekyll as build

COPY --from=source /app/website /srv/jekyll

ARG TARGET=/build

RUN mkdir -p ${TARGET} && chown jekyll.jekyll ${TARGET}

RUN jekyll build --destination ${TARGET}/_site && cat ${TARGET}/_site/docs/home/index.html ${TARGET}/_site/docs/setup/index.html ${TARGET}/_site/docs/concepts/index.html \
  ${TARGET}/_site/docs/tasks/index.html ${TARGET}/_site/docs/tutorials/index.html | \
  grep 'a class="item"' | grep 'href="/docs' | \
  uniq | cut -d'"' -f6 > ${TARGET}/_site/list

FROM madnight/docker-alpine-wkhtmltopdf as pdfs

ARG TARGET=/build

COPY --from=build ${TARGET}/_site /_site

WORKDIR /_site

RUN mkdir -p /out /out2 && apk add --no-cache ghostscript

RUN count=1 ; for l in $(cat list); do sed -i 's|/css/|/_site/css/|g;s|/js/|/_site/js/|g;s|/images/|/_site/images/|g' /_site${l}index.html || : ; wkhtmltopdf /_site${l}index.html /out/$(printf "%03d" $count)-$(echo $l | sed 's/^.\(.*\).$/\1/;s|/|-|g').pdf || : ; count=$((count+1)) ; done

WORKDIR /out

RUN gs -q -sPAPERSIZE=letter -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=/out2/out.pdf $(ls /out)

VOLUME /out3

ENTRYPOINT ["sh"]

CMD ["-c", "cp /out2/out.pdf /out3/"]
