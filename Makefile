NAME=aa864451000/vuepress-blog
TAG = master

build:
	echo building ${NAME}:${TAG}
	docker build -t ${NAME}:${TAG} .
	docker push "${NAME}:${TAG}"
