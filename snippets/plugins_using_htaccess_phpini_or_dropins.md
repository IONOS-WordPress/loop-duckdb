# customers using a plugin accessing .htacces, php.ini 

Paste this snippet into the report ui duckdb notebook and enable one of the queries at the bottom

```sql
--
-- select count of customers using one of the plugins accessing .htaccess, php.ini, or provide dropins
--

SELECT
  SPLIT_PART(plugin['plugin_slug']::VARCHAR, '/', 1) AS plugin_slug,
  COUNT(DISTINCT instance) AS count
FROM
  plugins
WHERE
  plugin_slug IN (
    'contact-form-7','all-in-one-seo-pack','elementor','woocommerce','wpforms-lite','wordpress-seo','simply-schedule-appointments','updraftplus','astra-sites','google-analytics-for-wordpress','google-listings-and-ads','wp-mail-smtp','maintenance','seo-by-rank-math','really-simple-ssl','wp-smushit','all-in-one-wp-migration','insert-headers-and-footers','ultimate-addons-for-gutenberg','real-cookie-banner','redirection','give','mailchimp-for-wp','wordfence','suremails','litespeed-cache','forminator','kadence-blocks','wp-fastest-cache','duplicator','wpconsent-cookies-banner-privacy-suite','gtranslate','wp-file-manager','wp-optimize','metform','autoptimize','broken-link-checker','cookie-notice','polylang','loco-translate','copy-delete-posts','wp-super-cache','wp-maintenance-mode','wp-statistics','unlimited-elements-for-elementor','imagify','popup-maker','wpvivid-backuprestore','ewww-image-optimizer','woocommerce-germanized','w3-total-cache','cartflows','wp-reset','woocommerce-pdf-invoices-packing-slips','backwpup','favicon-by-realfavicongenerator','surecart','better-wp-security','all-in-one-wp-security-and-firewall','advanced-google-recaptcha','facebook-for-woocommerce','matomo','nextgen-gallery','wp-staging','presto-player','wordpress-popup','tutor','wp-cloudflare-page-cache','greenshift-animation-and-page-builder-blocks','webp-converter-for-media','easy-digital-downloads','defender-security','insta-gallery','post-duplicator','site-reviews','health-check','ga-google-analytics','hummingbird-performance','qode-optimizer','integromat-connector','ad-inserter','booking','photo-gallery','everest-forms','migrate-guru','fluent-crm','google-language-translator','paid-memberships-pro','wp-2fa','cache-enabler','file-manager-advanced','zero-bs-crm','webp-express'
  )
GROUP BY
  plugin_slug
ORDER BY
  count DESC
;
```

```sql
---
--- get count of customers using one of the listed plugins, count of all unique customers and computed percentage 
---

SELECT
    COUNT(DISTINCT instance) AS customer_count,
    COUNT(DISTINCT instance) FILTER (
        WHERE
            SPLIT_PART(plugin['plugin_slug']::VARCHAR, '/', 1) IN (
              'contact-form-7','all-in-one-seo-pack','elementor','woocommerce','wpforms-lite','wordpress-seo','simply-schedule-appointments','updraftplus','astra-sites','google-analytics-for-wordpress','google-listings-and-ads','wp-mail-smtp','maintenance','seo-by-rank-math','really-simple-ssl','wp-smushit','all-in-one-wp-migration','insert-headers-and-footers','ultimate-addons-for-gutenberg','real-cookie-banner','redirection','give','mailchimp-for-wp','wordfence','suremails','litespeed-cache','forminator','kadence-blocks','wp-fastest-cache','duplicator','wpconsent-cookies-banner-privacy-suite','gtranslate','wp-file-manager','wp-optimize','metform','autoptimize','broken-link-checker','cookie-notice','polylang','loco-translate','copy-delete-posts','wp-super-cache','wp-maintenance-mode','wp-statistics','unlimited-elements-for-elementor','imagify','popup-maker','wpvivid-backuprestore','ewww-image-optimizer','woocommerce-germanized','w3-total-cache','cartflows','wp-reset','woocommerce-pdf-invoices-packing-slips','backwpup','favicon-by-realfavicongenerator','surecart','better-wp-security','all-in-one-wp-security-and-firewall','advanced-google-recaptcha','facebook-for-woocommerce','matomo','nextgen-gallery','wp-staging','presto-player','wordpress-popup','tutor','wp-cloudflare-page-cache','greenshift-animation-and-page-builder-blocks','webp-converter-for-media','easy-digital-downloads','defender-security','insta-gallery','post-duplicator','site-reviews','health-check','ga-google-analytics','hummingbird-performance','qode-optimizer','integromat-connector','ad-inserter','booking','photo-gallery','everest-forms','migrate-guru','fluent-crm','google-language-translator','paid-memberships-pro','wp-2fa','cache-enabler','file-manager-advanced','zero-bs-crm','webp-express'
            )
    ) AS customer_count_using_one_of_the_plugins,
    ROUND(CAST(customer_count_using_one_of_the_plugins AS DOUBLE) * 100.0 / customer_count, 2) AS percentage_of_customer_count
FROM
    plugins;
```

