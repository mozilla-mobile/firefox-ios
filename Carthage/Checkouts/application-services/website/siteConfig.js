const users = [
  {
    caption: 'User1',
    image: '/test-site/img/docusaurus.svg',
    infoLink: 'https://mozilla.org',
    pinned: true,
  },
];

const siteConfig = {
  title: 'Firefox Application Services' /* title for your website */,
  tagline: 'Build the next thing...',
  url: 'https://mozilla.github.io' /* your website url */,
  baseUrl: '/application-services/' /* base url for your project */,
  projectName: 'application-services',
  customDocsPath: 'docs/product-portal',
  headerLinks: [
    {blog: true, label: 'Blog'},
    {
      href: 'https://github.com/mozilla/application-services',
      label: 'GitHub',
    },
    { search: true },
    // {doc: 'doc1', label: 'Docs'},
    // {doc: 'doc4', label: 'API'},
  ],
  disableHeaderTitle: true,
  useEnglishUrl: false,
  users,
  /* path to images for header/footer */
  headerIcon: 'img/app-services.svg',
  footerIcon: 'img/app-services.svg',
  favicon: 'img/favicon.png',
  /* colors for website */
  colors: {
    primaryColor: '#424c55',
    secondaryColor: '#7A838B',
  },
  algolia: {
    apiKey: 'ebf54a0a9357f70ba426ce54714676d4',
    indexName: 'application_services'
  },
  // This copyright info is used in /core/Footer.js and blog rss/atom feeds.
  copyright:
    'Copyright © ' +
    new Date().getFullYear() +
    ' Firefox Application Services',
  organizationName: 'mozilla', // or set an env variable ORGANIZATION_NAME
  highlight: {
    // Highlight.js theme to use for syntax highlighting in code blocks
    theme: 'default',
  },
  scripts: ['https://buttons.github.io/buttons.js'],
  // You may provide arbitrary config keys to be used as needed by your template.
  repoUrl: 'https://github.com/mozilla/application-services',
  /* On page navigation for the current documentation page */
  onPageNav: 'separate',
  wrapPagesHTML: true,
  // Don't preprocess or concatenate mdBook stylesheets.
  separateCss: ['static/sync-storage-handbook', 'static/synconomicon'],
};

module.exports = siteConfig;
