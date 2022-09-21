
---COD---

select  C2.id                               [CustomerID],
        CAST(dbo.tobdt(ev.[When]) as DATE)  [Dates], 
        Amount                              [Amount], 
        Memo                                [Memo],
        left(right(memo,9),8)               [ShipmentTag]

from accounting.txn t
join accounting.account ac on t.accountid = ac.id
join accounting.event ev on ev.id = t.eventid
join customer c2 on c2.CustomerGuid = ac.[owner]
where Memo LIKE '%Cash on Delivery%'
and MEMO LIKE '%Chaldal Grocery%'
and accountHead = 'Own'
and ev.[When] >= '2022-06-08 00:00 +6:00'
and ev.[When] < '2022-06-15 00:00 +6:00'
order by 1 asc

-- Portwallet Payment---
select cast(dbo.tobdt(pw.SucceededOn) as date) SucceededOn,  
s.orderid OrderID, 
c.id Customerid,
-(amount) Amount,
pw.portwalletinvoiceid PortWalletInvoiceID

FROM shipment s
join payment.PaymentInvoiceMap pmap on pmap.InvoiceId = s.InvoiceId
join payment.PortwalletPayment pw on pw.id=pmap.portwalletpaymentid
join customer c on c.customerguid = pw.CreditAccount
where pw.SucceededOn >= '2022-04-01 00:00 +6:00'
and pw.SucceededOn < '2022-05-01 00:00 +6:00'
and Amount is not null
and SucceededOn is not null

group by cast(dbo.tobdt(pw.SucceededOn) as date), c.id, s.orderid, amount ,pw.portwalletinvoiceid


--Braintree Updated

SELECT CAST(dbo.tobdt(bp.SettledOn) as DATE) SettledOn,
c.id CustomerID, 
s.orderid OrderID,
-(Amount) Amount,
bp.braintreeTxId BrainTreeTransactionID

FROM shipment s
join payment.PaymentInvoiceMap pmap on pmap.InvoiceId = s.InvoiceId
join [Payment].BraintreePayment  bp on bp.id=pmap.braintreepaymentid
join customer c on c.customerguid = bp.CreditAccount
where bp.SettledOn >= '2022-06-08 00:00 +6:00'
and bp.SettledOn < '2022-06-15 00:00 +6:00'
and SettledOn is NOT NULL

group by CAST(dbo.tobdt(bp.SettledOn) as DATE),c.id, s.orderid, bp.braintreeTxId ,amount

order by 1 asc


--Bkash Refund--
select cast(dbo.tobdt(pb.CreatedOn) as date) Dates,
c.id Customerid, 
-(amount) Amount,
pb.BkashTxId BkashTransactionID,
s.orderid

FROM payment.PaymentInvoiceMap pmap
join payment.BkashPayment pb on pb.id=pmap.bkashpaymentid
join customer c on c.customerguid = pb.CreditAccount
left join shipment s on s.InvoiceId=pmap.InvoiceId
where pb.CreatedOn >= '2022-04-01 00:00 +6:00'
and pb.CreatedOn < '2022-05-01 00:00 +6:00'
and Amount is not null
and Status in  (1,11,12,10)
group by cast(dbo.tobdt(pb.CreatedOn) as date),c.id,pb.BkashTxId,amount,s.orderid


--Braintree Refund

Select pp.BraintreeTxId,
r.Amount,
cast(dbo.tobdt(r.createdon) as date) CreatedOn,
cast(dbo.tobdt(r.completedon) as date) Completedon,
r.Status,s.orderid,o.customerid,r.RefundedPaymentReference,r.BraintreePaymentId
from payment.Refund r
left join payment.BraintreePayment pp on pp.id=r.BraintreePaymentId
left join payment.PaymentInvoiceMap pim on pim.BraintreePaymentId=pp.id
left join shipment s on s.InvoiceId=pim.InvoiceId
left join [order] o on o.id=s.orderid
where r.CompletedOn is not null
and r.CompletedOn>='2022-06-08 00:00 +6:00'
and r.CompletedOn<'2022-06-15 00:00 +6:00'
and r.BraintreePaymentId is not null
order by 4 asc

----Reconciled Deliveries - (always filter �Salary� after getting the data)

select t.eventid,badgeid,e.FullName, Amount,Cast(dbo.tobdt([When]) as datetimeoffset) Dates,   Memo,ac.AccountHead
from accounting.txn t
join accounting.account ac on ac.id = t.accountid
join accounting.event ev on ev.id = t.eventid
join customer c on c.customerguid = ac.[owner]
join employee e on e.id = c.id
where [When] >= '2021-07-01 00:00 +6:00'
and [When] < '2022-06-01 00:00 +6:00'
and amount>0
and Memo LIKE  '%Reconciled Deliveries%'
order by 7 asc,5 asc,3 asc


--Corporate Order--

Select o.Id OrderId, c.Id CustomerID, c.FullName CustomerName, count(tr.SalePrice) QTY, sum(tr.SalePrice) SaleAmount

From ThingRequest tr
Join Shipment s on s.Id=tr.ShipmentId
Join [Order] o on o.Id=s.OrderId
Join Customer c on c.Id=o.CustomerId

Where s.ReconciledOn is  not null
and s.ReconciledOn >= '2022-06-01 00:00 +6:00'
and s.ReconciledOn < '2022-06-01 00:00 +6:00'
and tr.IsCancelled=0
and tr.IsMissingAfterDispatch=0
and tr.IsReturned=0
and tr.HasFailedBeforeDispatch=0
and c.IsCorporate=1

Group by
o.Id, c.Id, c.FullName


---Revenue Wastage---

select Cast(dbo.tobdt([When]) as datetimeoffset) Dates,
c.Id CustomerID,Amount, ac.AccountHead,Memo, ac.MoneyBalance, t.eventid
from accounting.txn t
join accounting.account ac on ac.id = t.accountid
join accounting.event ev on ev.id = t.eventid
join customer c on c.customerguid = ac.[owner]
join employee e on e.id = c.id
where [When] >= '2022-06-19 00:00 +6:00'
and [When] < '2022-06-20 00:00 +6:00'
and amount>0
--and Memo not LIKE  '%[Reconciled Deliveries]%'
and Memo LIKE  '%Revenue%'
order by 7 asc,5 asc,3 asc

-- Portwallet Refund

Select PP.PortwalletInvoiceId ,r.Amount,r.BraintreePaymentId,cast(dbo.tobdt(r.createdon) as date) CreatedOn,
cast(dbo.tobdt(r.completedon) as date) Completedon,
r.Status,s.orderid,o.customerid

from payment.Refund r
left join payment.PortwalletPayment pp on pp.id=r.PortwalletPaymentId
left join payment.PaymentInvoiceMap pim on pim.PortwalletPaymentId=pp.id
left join shipment s on s.InvoiceId=pim.InvoiceId
left join [order] o on o.id=s.orderid

where pp.SucceededOn is not null
and pp.SucceededOn>='2022-06-19 00:00 +6:00'
and pp.SucceededOn<'2022-06-20 00:00 +6:00'
and r.PortwalletPaymentId is not null
order by 4 asc




