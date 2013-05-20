# Amanda

Simple Blog engine powered by [Camping](http://camping.io).

Posts are written in [Markdown](http://daringfireball.net/projects/markdown/), saved on [Dropbox](https://www.dropbox.com/) and stored in [Redis](http://redis.io).

## Usage

Create a new markdown file with filename in the following format: `%Y%m%d%H%M.md` in the Amanda dropbox folder.

First lines must contain the `title`, `date` and can contain `tags` and / or `slug`. Followed by your post.

e.g.

    Title: Hello World
    Date: 2013-04-17 22:57
    Tags: tags, are, comma, separated
    Slug: this-slug-is-optional

    Hello World, first post!

To publish your new post hit the configured refresh url, e.g. http://blog.example.com/{your_refresh_path}

On the index page it always shows the most recent post and one random post.

## Deploy on heroku

Push the app to [Heroku](http://heroku.com) and [configure following environment variables](https://devcenter.heroku.com/articles/config-vars):

    DROPBOX_APP_KEY=your_dropbox_app_key
    DROPBOX_APP_SECRET=your_dropbox_app_secret
    OPENREDIS_URL=redis://127.0.0.1:6379 # set by Heroku on choosing service
    REDIS_SERVICE=OPENREDIS_URL # set your redis service
    AUTHOR=Koen Van der Auwera
    TITLE=Koen Van der Auwera's blog
    HAVEAMINT=http://your.mint.installation.url/?js # optional!
    SECRET=Some super session secret
    REFRESH_PATH=/refresh

## Example

[My blog](http://blog.atog.be).

## More

Fixes? Questions? Improvements? Let me know. Please.

## The MIT License (MIT)
Copyright (c) 2013 Koen Van der Auwera

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[http://opensource.org/licenses/MIT](http://opensource.org/licenses/MIT)