create table products
(
    price_list varchar               not null,
    brand      varchar               not null,
    code       varchar               not null,
    stock      integer default 0     not null,
    cost       integer default 0     not null,
    del        boolean default false not null,
    name       varchar,
    constraint products_pk
        primary key (price_list, brand, code)
);

create index products_price_list_index
    on products (price_list);

