# customers using a plugin accessing .htacces, php.ini 

Paste this snippet into the report ui duckdb notebook and enable one of the queries at the bottom

```sql
SELECT
  SPLIT_PART(plugin['plugin_slug']::VARCHAR, '/', 1) AS plugin_slug,
  COUNT(DISTINCT instance) AS count
FROM
  plugins
WHERE
  plugin_slug IN (
    'contact-form-7','all-in-one-seo-pack','elementor','woocommerce','wpforms-lite','wordpress-seo','simply-schedule-appointments','updraftplus','astra-sites','google-analytics-for-wordpress','google-listings-and-ads','wp-mail-smtp','maintenance','seo-by-rank-math','really-simple-ssl','wp-smushit','all-in-one-wp-migration','insert-headers-and-footers','ultimate-addons-for-gutenberg','real-cookie-banner','redirection','give','mailchimp-for-wp','wordfence','suremails','litespeed-cache','forminator','kadence-blocks','wp-fastest-cache','duplicator','kubio','wpconsent-cookies-banner-privacy-suite','gtranslate','wp-file-manager','wp-optimize','metform','autoptimize','broken-link-checker','cookie-notice','polylang','loco-translate','copy-delete-posts','wp-super-cache','wp-maintenance-mode','wp-statistics','unlimited-elements-for-elementor','imagify','popup-maker','wpvivid-backuprestore','ewww-image-optimizer','woocommerce-germanized','w3-total-cache','cartflows','wp-reset','woocommerce-pdf-invoices-packing-slips','backwpup','favicon-by-realfavicongenerator','surecart','better-wp-security','all-in-one-wp-security-and-firewall','advanced-google-recaptcha','facebook-for-woocommerce','matomo','nextgen-gallery','wp-staging','presto-player','wordpress-popup','tutor','wp-cloudflare-page-cache','greenshift-animation-and-page-builder-blocks','webp-converter-for-media','shortpixel-image-optimiser','bdthemes-prime-slider-lite','easy-digital-downloads','defender-security','insta-gallery','post-duplicator','site-reviews','health-check','ga-google-analytics','hummingbird-performance','qode-optimizer','integromat-connector','booking','photo-gallery','everest-forms','migrate-guru','fluent-crm','google-language-translator','paid-memberships-pro','wp-2fa','cache-enabler','file-manager-advanced','zero-bs-crm','webp-express'
  )
GROUP BY
  plugin_slug
ORDER BY
  count DESC
;
```

