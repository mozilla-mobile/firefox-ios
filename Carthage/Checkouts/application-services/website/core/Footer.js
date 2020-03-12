const React = require('react');

const siteConfig = require(process.cwd() + '/siteConfig.js');


function imgUrl(img) {
  return siteConfig.baseUrl + 'img/' + img;
}

class Footer extends React.Component {
  docUrl(doc, language) {
    const baseUrl = this.props.config.baseUrl;
    return baseUrl + 'docs/' + '' + doc;
  }

  pageUrl(doc, language) {
    const baseUrl = this.props.config.baseUrl;
    return baseUrl + '' + doc;
  }

  render() {
    return (
      <footer className="productShowcaseSection nav-footer"  id="footer">
        <section className="sitemap">
          <div>
            <a href="https://mozilla.org">
              <img src={ imgUrl('mozilla.svg') } style={{height: '50px'}} alt="Mozilla" />
            </a>
          </div>
          <div>
            <h5>Links</h5>
            <a href="/application-services/blog">
              Blog
            </a>
            <a href={this.docUrl('accounts/welcome.html', this.props.language)}>
            Firefox Accounts Docs
            </a>
            <a href={this.docUrl('applications/welcome.html', this.props.language)}>
              Firefox Applications Docs
            </a>
            <a href={this.docUrl('sync/welcome.html', this.props.language)}>
            Firefox Sync Docs
            </a>
          </div>
          <div>
            <h5>More</h5>
            <a href="https://github.com/mozilla/application-services">mozilla/application-services</a>
            <a href="https://github.com/mozilla/fxa">mozilla/fxa</a>
            <a href="https://github.com/mozilla">github/mozilla</a>
            <a href="https://github.com/mozilla-services">github/mozilla-services</a>
          </div>
        </section>

        <section className="copyright">
          Firefox Application Services
        </section>
      </footer>
    );
  }
}

module.exports = Footer;
