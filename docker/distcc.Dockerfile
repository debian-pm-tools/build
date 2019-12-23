FROM registry.gitlab.com/debian-pm/tools/build/debian:testing-amd64

RUN apt update && apt install distcc -y
ADD setup-distcc-runner.sh /usr/bin/setup-distcc-runner
RUN /usr/bin/setup-distcc-runner

CMD distccd --no-detach --allow-private --log-level=debug --log-stderr
