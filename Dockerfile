FROM ruby:3.2.0-buster

# Install dependencies
RUN \
  apt update && \
  apt install --yes libffi-dev

# Show full path in prompt
RUN echo 'PS1='\''imap-backup:$(pwd)>'\''' > /etc/bash.bashrc

# Create binstubs (including one for imap-backup) so we can run it
# without using `bundle exec`
ENV PATH ./bin/stubs:$PATH

WORKDIR /app

RUN gem install bundler --version=2.1.4
RUN gem install imap-backup

ENTRYPOINT ["bash"]
