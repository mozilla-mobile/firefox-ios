# SiteImageView

The purpose of this library is to manage image meta data from websites such as favicons and hero images.

To use this library you need to import SiteImageView and create either a FaviconImageView or a HeroImageView.


# Favicons

Create an object of type FaviconImageView and use it as you would any other image view, setting it's 
constraints etc. To populate it call setFavicon and give it a FaviconImageViewModel with the data of the 
website you want to load. 

If you have the favicon URL available you can pre-emptively add it to the cache by creating a SiteImageHandler
and calling cacheFaviconURL. This will avoid an unnecessary visit to the website when the FaviconImageView 
is loaded.

If the favicon cannot be retrieved using the site URL then the system will automatically fallback to 
generate a favicon style image using the first letter of the site domain, giving it a random background
color.


# Hero Images

Create an object of type HeroImageView and use it as you would any other image view, setting it's 
constraints etc. To populate it call setHeroImage giving it a HeroImageViewModel with the data of the
website you want to load.

If the page has no hero image or for some reason it cannot be retrieved the system will fallback to using
a favicon as described above.


# General

All caching of URL's and images are managed by the SiteImageView system, they are cached both locally and to disk. 
The disk caches are automatically expired after 30 days of no use so they don't grow too big over time.


# Future development

This is a somewhat simplified implementation of a favicon system. It retrieves the first favicon or icon it can find
on a given website and uses that everywhere. Many websites have several favicons of different sizes for 
different use cases, this system will ignore all but the first. 
This can be built upon in future to store multiple favicons per domain but this was out of scope for the 
MVP of this project. We will likely come back at a later time and develop it further to support these
more complex use cases. 
