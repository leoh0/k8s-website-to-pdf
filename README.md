# k8s-website-to-pdf

You can build and get pdf.

```
docker build -t k8s-website-to-pdf .
docker run -ti -v $PWD:/out3 k8s-website-to-pdf
```

Or get old pdf from prebuilded image.

```
docker run -ti -v $PWD:/out3 leoh0/k8s-website-to-pdf
```
