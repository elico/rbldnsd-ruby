SELECT u.url, c.name, c.categroy_id, c.description  FROM px.url u 
JOIN px.Category c 
ON u.category_id = c.categroy_id WHERE u.url IN ( '.sex.com' );
