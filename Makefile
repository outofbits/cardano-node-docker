latest: 1.25.1

1.25.1:
	./build.sh "1.25.1"

1.25.0:
	./build.sh "1.25.0"

1.24.2:
	./build.sh "1.24.2"

1.24.1:
	./build.sh "1.24.1"

1.24.0:
	./build.sh "1.24.0"

1.23.0:
	./build.sh "1.23.0"

base-image:
	./build-base.sh

base-compile-image: #base-image 
	./build-base-compiler.sh "8.10.3" "3.2.0.0"
