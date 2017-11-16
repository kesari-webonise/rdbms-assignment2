-- create database 
create database e_commerce;

-- create users table 
create table users(id int primary key auto_increment not null, name varchar(20) not null, role varchar(10) not null, email varchar(50) unique not null, password varchar(15) not null, contact varchar(10) not null, address varchar(50) not null, created_date date not null, updated_date date not null);

-- insert data into users table
insert into users(name,role,email,password,contact,address,created_date,updated_date) values('kp','buyer','kp@weboniselab.com','12345678','1234567890','pune',curDate(),curDate());

insert into users(name,role,email,password,contact,address,created_date,updated_date) values('kp','buyer','pk@weboniselab.com','12345678','1234567890','pune',curDate(),curDate());

insert into users(name,role,email,password,contact,address,created_date,updated_date) values('np','buyer','np@weboniselab.com','12345678','1234567890','pune',curDate(),curDate());

-- create products table
create table products(id int primary key auto_increment not null, product_name varchar(20) not null,created_date date not null, updated_date date not null);

-- insert data into products
insert into products(product_name,created_date,updated_date) values('kurta',curDate(),curDate());
insert into products(product_name,created_date,updated_date) values('shirt',curDate(),curDate());
insert into products(product_name,created_date,updated_date) values('jeans',curDate(),curDate());

-- create variants table
create table variants(id int primary key auto_increment not null, product_id int foreign key references products(id), color_name varchar(10) not null, stock int not null,price decimal(6,2) not null,created_date date not null, updated_date date not null);

-- insert data into variants
insert into variants(product_id,color_name,stock,price,created_date,updated_date) values(1,'red',10,200,curDate(),curDate());
insert into variants(product_id,color_name,stock,price,created_date,updated_date) values(1,'green',10,250,curDate(),curDate());
insert into variants(product_id,color_name,stock,price,created_date,updated_date) values(2,'pink',10,300,curDate(),curDate());
insert into variants(product_id,color_name,stock,price,created_date,updated_date) values(2,'white',10,350,curDate(),curDate());
insert into variants(product_id,color_name,stock,price,created_date,updated_date) values(3,'black',10,400,curDate(),curDate());
insert into variants(product_id,color_name,stock,price,created_date,updated_date) values(3,'red',10,450,curDate(),curDate());

-- create orders table 
create table orders(id int primary key not null auto_increment, user_id int references users(id),order_date date not null, order_status varchar(20) not null, final_cost decimal(6,2) not null , shipping_date date not null , created_date date not null, updated_date date not null); 

-- create carts table
create table carts(user_id int references users(id), variant_id int references variants(id),product_id int references products(id),product_quantity int not null, order_id int references orders(id),created_date date not null, updated_date date not null); 

-- create payments table
create table payments(id int primary key not null auto_increment, order_id int references orders(id), payment_type varchar(20) not null,discount_coupon decimal(3,2) not null, payment_date date not null, payment_status varchar(20) not null,created_date date not null, updated_date date not null);

-- create order_history table
create table order_history(user_id int references users(id),variant_id int references variant(id),product_id int references product(id),order_id int referenes order(id),created_date date not null, updated_date date not null); 

-- create procedure check_product_availability - which checks whether sufficient stock is available or not
delimiter // ;
create procedure check_product_availability(in variant_id int,in quantity int, out status int)
      begin
          declare stock_avail int;

          select stock into stock_avail from variants where id=variant_id;

         if stock_avail>=quantity then
              set status=1;
             
else
          set status=0;
end if;
end//
delimiter ; //

-- create procedure add_to_cart - it addes products to cart
delimiter // ;
create procedure add_to_cart(in variant_id int,in quantity int)
begin 
declare status int; 
call check_product_availability(variant_id,quantity,status); 
if status =1 then
  update variants set stock=stock-quantity where id=variant_id;
  insert into carts values(variant_id,quantity,curDate(),curDate());
end if;
end//     
delimiter ; //

-- create procedure make_payment - to pay payment of given order
delimiter // ;
create procedure make_payment(in orderid int)
      begin
         declare checkoutcost int;
         declare discount_coupon int;
         start transaction;
         set discount_coupon=50.00;	
         set checkoutcost= (select  final_cost from orders where id=orderid);
         insert into payments(order_id, payment_type, discount_coupon, payment_date, payment_status,created_date,updated_date,checkout_cost) values(orderid,'credit card',discount_coupon,curDate(),'done',curDate(),curDate(),checkoutcost-50.00);

update orders set order_status='dispatched' where id=orderid;
      commit;
      end//
delimiter ; //

-- view order_details - order details of products sold
Create view order_details as select orders.id as 'Order Id',final_cost as 'Order Total',order_date as 'Date',discount_coupon as 'Discount',payment_type as 'Payment method',payment_status as 'Payment status' from orders,payments where orders.id=order_id;

-- monthly report
create view monthly_report as 
select orders.id as 'Order id',order_date as 'Order date',product_name as 'Product name',order_history.product_quantity as 'Quantity',variants.price as 'Per unit price',payments.checkout_cost as 'Final order cost',name as 'User name',email as 'Email'  from orders,order_history,variants,products,users,payments where orders.id=order_history.order_id and order_history.variant_id=variants.id and users.id=orders.user_id and orders.id=payments.order_id and variants.product_id=products.id and order_date between DATE_FORMAT(CURDATE(),'%Y-%m-01') and curDate();

-- create procedure move_to_order_history - moves products from cart to order history
delimiter //
create procedure move_to_order_history(in orderid int)
begin
declare variantid int;
declare productquantity int;
declare createddate date;
declare updateddate date;
declare done int default false;

declare cart_cur cursor for select variant_id, product_quantity, created_date, updated_date from carts;

declare continue handler for not found set done=true;
open cart_cur;
read_loop: loop
     fetch cart_cur into  variantid, productquantity, createddate, updateddate;
     if done then
         leave read_loop;
    end if;
    insert into order_history values(variantid,productquantity,orderid,createddate, updateddate);
end loop;
close cart_cur;
end//
delimiter ;

-- create procedure place_order - to place order
delimiter //
create procedure place_order(in user_id int)
begin
declare total int; 
declare orderid int;

select total;
set total= (select sum(price*product_quantity) from variants, carts where id=variant_id); 
select total;

insert into orders(user_id,order_date,order_status,final_cost,shipping_date,created_date,updated_date) values(user_id,curDate(),'placed',total,ADDDATE(curDate(), interval 3 day),curDate(),curDate());

select orderid;
select id into orderid from orders order by id desc limit 1;
select orderid;

call  move_to_order_history(orderid);
truncate table carts;
end//
delimiter ;


