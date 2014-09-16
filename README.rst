Docker Guidebook
================
This is git repo for the Docker Guidebook that I'm writing, feel free to fork and submit pull requests to make this better. 

The goal is to release online and as a free downloadable ebook.

The book is currently written in ReStructuredText, but might be converted to Latex in future if needed.

Book is currently written for Docker 0.5, and will be updated with each release. Once we hit the Docker 1.0 release, we will look at getting hard copies created if there is a demand.

Still looking for the best open source license, any suggestions let me know.

Thanks,
Ken


Getting started
===============
This guide is currently written in `ReStructuredText <http://docutils.sourceforge.net/rst.html>`_ and requires `Sphinx <http://sphinx-doc.org/>`_ to generate the HTML version. The easiest way to do this is the following.

1. Install sphinx::

    $ easy_install -U Sphinx
    
    or
    
    $ pip install -r requirements.txt

2. Build the html::

    $ make

3. View the results::

    $ make server
    # open browser to http://localhost:8000/docker-guidebook.html
