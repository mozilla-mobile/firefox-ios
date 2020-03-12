const React = require('react');

const CompLibrary = require('../../core/CompLibrary.js');
const MarkdownBlock = CompLibrary.MarkdownBlock; /* Used to read markdown */
const Container = CompLibrary.Container;
const GridBlock = require(process.cwd() + '/core/GridBlock.js');

const MetadataBlog = require('../../core/MetadataBlog.js');

const siteConfig = require(process.cwd() + '/siteConfig.js');

function imgUrl(img) {
  return siteConfig.baseUrl + 'img/' + img;
}

function docUrl(doc, language) {
  return siteConfig.baseUrl + 'docs/' + (language ? language + '/' : '') + doc;
}

function pageUrl(page, language) {
  return siteConfig.baseUrl + (language ? language + '/' : '') + page;
}

class Button extends React.Component {
  render() {
    return (
      <div className="pluginWrapper buttonWrapper">
        <a className="button" href={this.props.href} target={this.props.target}>
          {this.props.children}
        </a>
      </div>
    );
  }
}

Button.defaultProps = {
  target: '_self',
};

const SplashContainer = props => (
  <div className="homeContainer">
    <div className="homeSplashFade">
      <div className="wrapper homeWrapper">{props.children}</div>
    </div>
  </div>
);

const Logo = props => (
  <div className="projectLogo">
    <img src={props.img_src} />
  </div>
);

const ProjectTitle = props => (
  <h2 className="projectTitle">
    <small>{siteConfig.tagline}</small>
  </h2>
);

const PromoSection = props => (
  <div className="section promoSection">
    <div className="promoRow">
      <div className="pluginRowBlock">{props.children}</div>
    </div>
  </div>
);

class HomeSplash extends React.Component {
  render() {
    let language = this.props.language || '';
    return (
      <SplashContainer>
        <Logo img_src={imgUrl('services-glyph.svg')} />
        <div className="inner">
          <ProjectTitle />
          <PromoSection>
          </PromoSection>
        </div>
      </SplashContainer>
    );
  }
}

const Block = props => (
  <Container
    padding={['bottom', 'top']}
    id={props.id}
    background={props.background}>
    <GridBlock align="center" contents={props.children} layout={props.layout} />
  </Container>
);

const Features = props => (
  <Block layout="fourColumn">
    {[
      {
        imageAlign: 'top',
        title: 'Accounts',
        imageLink: `${siteConfig.baseUrl}docs/accounts/welcome.html`,
        image: imgUrl('login-16.svg'),
      },
      {
        imageAlign: 'top',
        title: 'Applications',
        imageLink: `${siteConfig.baseUrl}docs/applications/welcome.html`,
        image: imgUrl('apps.svg'),
      },
      {
        imageAlign: 'top',
        title: 'Sync',
        imageLink: `${siteConfig.baseUrl}docs/sync/welcome.html`,
        image: imgUrl('sync-16.svg'),
      },
      {
        imageAlign: 'top',
        title: 'Push',
        imageLink: `${siteConfig.baseUrl}docs/push/welcome.html`,
        image: imgUrl('notification-16.svg'),
      },
    ]}
  </Block>
);

const FeatureCallout = props => (
  <div
    className="productShowcaseSection customFeatureCallout paddingBottom"
    style={{textAlign: 'center'}}>
    <h2>Integrate your projects with Firefox Accounts</h2>
    <a className="button" href={ siteConfig.baseUrl + 'docs/accounts/welcome.html' }>
      Integrate Now
    </a>
  </div>
);

const LearnHow = props => (
  <Block background="light">
    {[
      {
        content: 'Talk about learning how to use this',
        image: imgUrl('accounts.svg'),
        imageAlign: 'right',
        title: 'Learn How',
      },
    ]}
  </Block>
);

const TryOut = props => (
  <Block id="try">
    {[
      {
        content: 'Talk about trying this out',
        image: imgUrl('accounts.svg'),
        imageAlign: 'left',
        title: 'Try it Out',
      },
    ]}
  </Block>
);

const Description = props => (
  <Block background="dark">
    {[
      {
        content: 'This is another description of how this project is useful',
        image: imgUrl('accounts.svg'),
        imageAlign: 'right',
        title: 'Description',
      },
    ]}
  </Block>
);


const Products = props => (
  <div
    className="productShowcaseSection paddingBottom"
    style={{textAlign: 'center'}}>
    <h2>Products</h2>
  <Block layout="fourColumn">
    {[
      {
        image: 'https://www.mozilla.org/media/img/logos/firefox/logo-quantum-wordmark-white.bd1944395fb6.png',
        imageAlign: 'top',
        title: 'Firefox',
        imageLink: `https://www.mozilla.org/en-US/firefox/new/`
      },
      {
        image: imgUrl('accounts.svg'),
        imageAlign: 'top',
        title: 'Lockbox',
        imageLink: 'https://lockbox.firefox.com/'
      },
      {
        image: 'https://testpilot.firefox.com/static/images/experiments/notes/experiments_experiment/thumbnail.2b29f3e8.png',
        imageAlign: 'top',
        title: 'Notes',
        imageLink: 'https://testpilot.firefox.com/experiments/notes'
      },
      {
        image: imgUrl('testpilot.svg'),
        imageAlign: 'top',
        title: 'Firefox Focus',
        imageLink: 'https://www.mozilla.org/en-US/firefox/mobile/'
      },
    ]}
  </Block>
  </div>
);

const Showcase = props => {
  if ((siteConfig.users || []).length === 0) {
    return null;
  }
  const showcase = siteConfig.users
    .filter(user => {
      return user.pinned;
    })
    .map((user, i) => {
      return (
        <a href={user.infoLink} key={i}>
          <img src={user.image} title={user.caption} />
        </a>
      );
    });

  return (
    <div className="productShowcaseSection paddingBottom">
      <h2>{"Who's Using This?"}</h2>
      <p>This project is used by all these people</p>
      <div className="logos">{showcase}</div>
      <div className="more-users">
        <a className="button" href={pageUrl('users.html', props.language)}>
          More {siteConfig.title} Users
        </a>
      </div>
    </div>
  );
};


const BlogPosts = props => {
  const blogposts = MetadataBlog
    .slice(0, 8)
    .map((post, i) => {
      const match = post.path.match(/([0-9]+)\/([0-9]+)\/([0-9]+)/);
      // Because JavaScript sucks at date handling :(
      const year = match[1];
      const month = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][parseInt(match[2], 10) - 1];
      const day = parseInt(match[3], 10);

      return (
        <div className="blockElement alignCenter fourByGridBlock imageAlignTop" key={i}>
        <a href={"/application-services/blog/" + post.path}>
          <h3 className="indexPostTitle">{post.title}</h3>
          <p>by {post.author} on {month} {day}, {year}</p>
        </a>
        </div>
      );
    });

  return (
      <div className="productShowcaseSection container paddingBottom paddingTop">
        <h2>{"Recent Blog Posts"}</h2>
        <div className="gridBlock">
          {blogposts}
        </div>
      </div>
  );

};

class Index extends React.Component {
  render() {
    let language = this.props.language || '';

    return (
      <div>
        <HomeSplash language={language} />
        <div className="mainContainer">
          <Features />
          <FeatureCallout />
          <BlogPosts />
        </div>
      </div>
    );
  }
}

module.exports = Index;
