FROM ruby:2.7

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client libvips

WORKDIR /myapp
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Remove the bootsnap line — it breaks on Render's old image
# No precompile needed — Rails 7 boots fine without it

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
