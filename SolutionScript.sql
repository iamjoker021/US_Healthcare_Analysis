/****** Script for SelectTopNRows command from SSMS  ******/

-- Section 1

-- Problem 1
with cte as (
SELECT t.treatmentID
      ,p.patientID
	  ,p.dob
	  -- ,datediff(year, p.dob, getdate()) as age
	  ,case 
		when datediff(year, p.dob, getdate()) between 1 and 14 then 'Children'
		when datediff(year, p.dob, getdate()) between 15 and 24 then 'Youth'
		when datediff(year, p.dob, getdate()) between 25 and 64 then 'Adults'
		when datediff(year, p.dob, getdate()) between 65 and 130 then 'Seniors'
		else 'InValid'
	  end as Age_Category
  FROM [Treatment] t
  join Patient p  on p.patientID = t.patientID
  where year(t.date) = 2022
)
select Age_Category, count(treatmentID) from cte
group by Age_Category;


-- Problem 2
-- If Female count is 0 then ratio is NULL to avoid DivByZero error
with cte as (
select 
	d.diseaseName 
	-- ,pers.gender
	,sum(iif(pers.gender = 'male', 1, 0)) as male_cnt
	,sum(iif(pers.gender = 'female', 1, 0)) as female_cnt
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pers on pers.personID = p.patientID
group by d.diseaseName
)
select 
	diseaseName
	,male_cnt
	,female_cnt
	,iif(female_cnt > 0, male_cnt*1.0/female_cnt, NULL) as male_to_femal_ratio
	,male_cnt * 100.0/(male_cnt+female_cnt) as male_percent
	,female_cnt * 100.0/(male_cnt+female_cnt) as female_percent
from cte;

-- Problem 3
with cte as
(select
	pers.gender
	-- ,t.treatmentID
	-- ,c.claimID
	,count(t.treatmentID) as treatment_cnt
	,count(c.claimID) as claim_cnt
from Treatment t
join Patient p on p.patientID = t.patientID
join Person pers on pers.personID = p.patientID
left join Claim c on c.claimID = t.claimID
group by pers.gender
)
select
	gender
	,treatment_cnt
	,claim_cnt
	,claim_cnt * 100.0/treatment_cnt
from cte;
-- Also about 40% are not claimed

-- Problem 4
select
	p.pharmacyName
	,sum(k.quantity) as medicin_cnt
	,sum(k.quantity * m.maxPrice) as total_price
	,sum( (k.quantity * m.maxPrice) * (100 - k.discount)/100.0) as total_price_after_discount
from Medicine m
join Keep k  on k.medicineID = m.medicineID
join Pharmacy p on p.pharmacyID = k.pharmacyID
group by p.pharmacyName;


-- Problem 5
with cte as
(select
	s.pharmacyName
	,p.prescriptionID
	,sum(c.quantity) as med_cnt_per_pres
from Pharmacy s
join Prescription p on p.pharmacyID = s.pharmacyID
join Contain c on c.prescriptionID = p.prescriptionID
group by s.pharmacyName, p.prescriptionID
)
select
	pharmacyName
	,avg(med_cnt_per_pres) as avg_med_per_pres
	,max(med_cnt_per_pres) as max_med_per_pres
	,min(med_cnt_per_pres) as min_med_per_pres
from cte
group by pharmacyName;

-- Section 2

-- Problem 1
-- The Count of Prescription is low and not getting 1000. Hence kept 7 instead of 1000
select top 3
	a.city
	-- ,s.pharmacyName
	-- ,p.prescriptionID
	,count(distinct s.pharmacyName) as pharmacy_cnt
	,count(distinct p.prescriptionID) as prescription_cnt
	,count(distinct s.pharmacyName) * 100.0 / count(distinct p.prescriptionID) as phar_to_pres
from Pharmacy s
join Prescription p on p.pharmacyID = s.pharmacyID
join Address a on a.addressID = s.addressID
-- order by s.pharmacyName
group by a.city
having count(distinct p.prescriptionID) > 1000
order by phar_to_pres
;

-- Problem 2
with cte as
(select 
	a.city
	,d.diseaseName
	-- ,pn.personID
	,count(p.patientID) as dis_cnt
	,rank() over(partition by a.city order by count(p.patientID) desc) as rnk
from Disease d 
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where a.state = 'AL'
group by a.city, d.diseaseName)
select 
	city
	,diseaseName
	,dis_cnt
from cte
where rnk = 1
;


-- Problem 3
with cte as
(select 
	d.diseaseName
	,i.planName
	,count(c.claimID) as cnt_per_plan_disease
	,ROW_NUMBER() over(partition by d.diseaseName order by count(c.claimID) desc) as max_rnk
	,ROW_NUMBER() over(partition by d.diseaseName order by count(c.claimID) ) as min_rnk
from Claim c
join InsurancePlan i on i.uin = c.uin
join Treatment t on t.claimID = c.claimID
join Disease d on d.diseaseID = t.diseaseID
group by d.diseaseName, i.planName
)
select
	c1.diseaseName
	,c1.planName as max_plan
	,c2.planName as min_plan
from cte c1
join cte c2 on c1.diseaseName = c2.diseaseName
where c1.max_rnk = 1 and c2.min_rnk = 1
;

-- Problem 4
with cte as
(select 
	d.diseaseName
	,a.addressID
	,count(p.patientID) as patient_cnt
from Disease d 
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by d.diseaseName ,a.addressID
having count(p.patientID) > 1)
select 
	diseaseName
	,COUNT(addressID) as household_cnt
from cte
group by diseaseName
order by household_cnt desc;


-- Problem 5
with cte as
(select
	a.state
	-- ,t.treatmentID
	-- ,c.claimID
	,count(t.treatmentID) as treatment_cnt
	,count(c.claimID) as claim_cnt
from Treatment t
join Patient p on p.patientID = t.patientID
join Person pers on pers.personID = p.patientID
join Address a on a.addressID = pers.addressID
left join Claim c on c.claimID = t.claimID
where t.date between '01-APR-2021' and '31-MAR-2022'
group by a.state
)
select
	state
	,treatment_cnt
	,claim_cnt
	,claim_cnt * 100.0/treatment_cnt
from cte;

-- Section 3

-- Problem 1
with cte as
(select 
	YEAR(t.date) as 'year'
	,s.pharmacyName
	,count(m.hospitalExclusive) as exc_cnt
	,dense_rank() over(
		partition by YEAR(t.date) 
		order by count(m.hospitalExclusive) desc 
		) as rnk
from Pharmacy s
join Prescription p on p.pharmacyID = s.pharmacyID
join Treatment t on t.treatmentID = p.treatmentID
join Contain c on c.prescriptionID = p.prescriptionID
join Medicine m on m.medicineID = c.medicineID
where YEAR(t.date) in (2022, 2021) and
m.hospitalExclusive = 'S'
group by YEAR(t.date), s.pharmacyName)
select 
	year
	,pharmacyName
	,exc_cnt
from cte
where rnk  = 1
;

-- Problem 2
select 
	ip.planName
	,ic.companyName
	,count(t.treatmentID) as cnt_of_treatment_claimed
from InsurancePlan ip
join InsuranceCompany ic on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
join Treatment t on t.claimID = c.claimID
group by ip.planName, ic.companyName
;

-- Problem 3
with cte as
(
select 
	ic.companyName
	,ip.planName
	,count(c.claimID) as clain_cnt
	,rank() over(partition by ic.companyName order by count(c.claimID) desc) as high_rnk
	,rank() over(partition by ic.companyName order by count(c.claimID)) as low_rnk
from InsurancePlan ip
join InsuranceCompany ic on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
group by ic.companyName, ip.planName
)
,cte1 as
(select 
	planName
	,companyName
from cte
where high_rnk = 1)
,cte2 as
(select 
	planName
	,companyName
from cte
where low_rnk = 1)
select 
	c1.companyName
	,c1.planName as most_plan
	,c2.planName as least_plan
from cte1 c1
join cte2 c2 on c1.companyName = c2.companyName
;

-- Problem 4
select 
	a.state
	,count(p.personID) as pers_cnt
	,count(pt.patientID) as patient_cnt
	,count(pt.patientID) * 100.0/ count(p.personID) as patient_person_ration
from Person p
left join Patient pt on pt.patientID = p.personID
join Address a on a.addressID = p.addressID
group by a.state
;

-- Problem 5
select 
	s.pharmacyName
	,sum(c.quantity) as med_cnt
from Medicine m
join Contain c on c.medicineID = m.medicineID
join Prescription p on p.prescriptionID = c.prescriptionID
join Pharmacy s on s.pharmacyID = p.pharmacyID
join Address a on a.addressID = s.addressID
join Treatment t on t.treatmentID = p.treatmentID
where m.taxCriteria = 'I'
and year(t.date) = 2021
and a.state = 'AZ'
group by s.pharmacyName;

-- Section 4

-- Problem 1
select 
	productName
	,productType
	,CASE productType
		WHEN 1 THEN 'Generic'
		WHEN 2 THEN 'Patent'
		WHEN 3 THEN 'Reference'
		WHEN 4 THEN 'Similar'
		WHEN 5 THEN 'New'
		WHEN 6 THEN 'Specific'
		WHEN 7 THEN 'Biological'
		WHEN 8 THEN 'Dinamized'
		ELSE 'Unknown'
	END as productCategory
from Medicine
where (taxCriteria = 'I' and productType in (1, 2, 3) )
or (taxCriteria = 'II' and productType in (4, 5, 6) )
;


-- Problem 2
select 
	p.prescriptionID
	,sum(c.quantity) as med_cnt
	,case 
		when sum(c.quantity) < 3 then 'low'
		when sum(c.quantity) < 5 then 'medium'
		else 'high'
	end as category
from Prescription p 
join Contain c on c.prescriptionID = p.prescriptionID
group by p.prescriptionID;


-- Problem 3
with cte as
(select
	p.pharmacyName
	,m.productName
	,k.quantity
	,case
		when k.quantity < 1000 then 'low'
		when k.quantity <= 7500 then 'medium'
		else 'high'
	end as qnt_cat
	,k.discount
	,case
		when k.discount = 0 then 'none'
		when k.discount < 30 then 'med'
		else 'high'
	end as discount_cat
from Keep k
join Pharmacy p on p.pharmacyID = k.pharmacyID
join Medicine m on m.medicineID = k.medicineID
where pharmacyName = 'Spot Rx'
)
select 
	productName
	,qnt_cat
	,discount_cat
from cte
where (qnt_cat = 'low' and discount_cat='high')
or (qnt_cat = 'high' and discount_cat='none')
;


-- Problem 4
with cte as
(select 
	productName
	,maxPrice
	, case
		when maxPrice < 0.5 * avg(maxPrice) over() then 'low'
		when maxPrice > 2 * avg(maxPrice) over() then 'high'
		else NULL
	end as cat
from Medicine)
select 
	productName
	,maxPrice
	,cat
from cte
where cat is not Null
;

-- Problem 5
select
	p.personName
	,p.gender
	,pt.dob
	,  CASE
		WHEN pt.dob >= '2005-01-01' AND gender = 'Male' THEN 'YoungMale'
		WHEN pt.dob >= '2005-01-01' AND gender = 'Female' THEN 'YoungFemale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Male' THEN 'AdultMale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Female' THEN 'AdultFemale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Male' THEN 'MidAgeMale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Female' THEN 'MidAgeFemale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Male' THEN 'ElderMale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Female' THEN 'ElderFemale'
		ELSE 'Unknown'
	END

from Patient pt
join Person p on p.personID = pt.patientID;

-- Section 5

-- Problem 1
select
	pn.personName
	,datediff(year, p.dob, getdate()) as age
	,count(t.treatmentID) as treatment_cnt
from Patient p
join Person pn on pn.personID = p.patientID
join Treatment t  on t.patientID = p.patientID
group by pn.personName, datediff(year, p.dob, getdate())
order by treatment_cnt desc


-- Problem 2
select 
	d.diseaseName
	-- ,pn.gender
	,sum(iif(pn.gender='male', 1, 0)) as male_cnt
	,sum(iif(pn.gender='female', 1, 0)) as femal_cnt
	,sum(iif(pn.gender='male', 1, 0)) * 1.0 / sum(iif(pn.gender='female', 1, 0)) as male_female_ration
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
where year(t.date) = 2021
group by d.diseaseName;


-- Problem 3
with cte as
(select 
	d.diseaseName
	,a.city
	,count(t.treatmentID) as treatment_cnt
	,rank() over(partition by d.diseaseName order by count(t.treatmentID) desc) as rnk
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by d.diseaseName, a.city)
select 
	diseaseName
	,city
	,treatment_cnt
from cte
where rnk <= 3
order by diseaseName, rnk;

-- Problem 4
select
	s.pharmacyName
	,d.diseaseName
	-- ,year(t.date) as yr
	,sum( iif(year(t.date) = 2021, 1, 0) ) as '2021_cnt'
	,sum( iif(year(t.date) = 2022, 1, 0) ) as '2022_cnt'
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Prescription p on p.treatmentID = t.treatmentID
join Pharmacy s on s.pharmacyID = p.pharmacyID
where year(t.date) in (2021, 2022)
group by pharmacyName, d.diseaseName;

-- Problem 5
with cte as
(select
	ic.companyName
	,a.state
	,count(p.patientID) as patient_cnt
	,rank() over(partition by ic.companyName order by count(p.patientID) desc) as rnk
from InsuranceCompany ic
join InsurancePlan ip on ip.companyID = ic.companyID
join Claim c on c.uin = ip.uin
join Treatment t on t.claimID = c.claimID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by ic.companyName, a.state)
select
	*
from cte
where rnk = 1;


-- Section 6

-- Problem 1
select 
	s.pharmacyID
	,s.pharmacyName
	,sum(c.quantity) as med_cnt
	,sum( iif(m.hospitalExclusive = 'S', c.quantity, 0) ) as hosp_exc_cnt
	,sum( iif(m.hospitalExclusive = 'S', c.quantity, 0) ) * 100.0 / sum(c.quantity) as med_exc_norm_ration
from Pharmacy s
join Prescription p on s.pharmacyID = p.pharmacyID
join Treatment t on t.treatmentID = p.treatmentID
join Contain c on c.prescriptionID = p.prescriptionID
join Medicine m on m.medicineID = c.medicineID
where year(t.date) = 2021
group by s.pharmacyID,s.pharmacyName;

-- Problem 2
select
	a.state
	,count(c.claimID) as claim_cnt
	,count(t.treatmentID) as treat_cnt
	,100 - ( count(c.claimID) * 100.0/ count(t.treatmentID) ) as no_claim_per_total_treatment
from Treatment t
join Patient p on p.patientID = t.patientID
join Person pers on pers.personID = p.patientID
left join Claim c on c.claimID = t.claimID
join Address a on a.addressID = pers.addressID
group by a.state;


-- Problem 3
with cte as
(select 
	a.state
	,d.diseaseName
	,count(p.patientID) as dis_cnt
	,rank() over(partition by a.state order by count(p.patientID) desc) as max_rnk
	,rank() over(partition by a.state order by count(p.patientID) ) as min_rnk
from Disease d 
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where year(t.date) = 2022
group by a.state, d.diseaseName)
select 
	c1.state
	,c1.diseaseName as most_disease
	,c2.diseaseName as least_disease
from cte c1
join cte c2 on c1.state = c2.state
where c1.max_rnk = 1 and c2.min_rnk = 1;


-- Problem 4
select
	a.city
	,count(pn.personID) as pers_cnt
	,count(p.patientID) as pat_cnt
	,count(p.patientID) * 100.0 / count(pn.personID) as pat_per_ration
from Person pn
left join Patient p on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
group by a.city
having count(pn.personID) > 10


-- Problem 5
select top 3
	p.pharmacyName
	,sum(k.quantity) as med_cnt
from Medicine m
join Keep k on k.medicineID = m.medicineID
join Pharmacy p on p.pharmacyID = k.pharmacyID
where m.substanceName like '%ranitidin%'
group by p.pharmacyName
order by med_cnt desc;


-- Section 7

-- Problem 1

create procedure is_cnt_higher_than_avg(@diseaseID int)
as
BEGIN
	IF (select 
		count(t.claimID)
	from Disease d
	join Treatment t on d.diseaseID = t.diseaseID
	where d.diseaseID = @diseaseID ) > (select 
										count(claimID)
										from Treatment)
		BEGIN
			select 'claimed higher than average' as status
		END
	ELSE
		BEGIN
			select 'claimed lower than average' as status
		END
END;

exec is_cnt_higher_than_avg 4;

-- Problem 2
drop procedure get_gender_cnt;
create procedure get_gender_cnt(@diseaseID int)
as
	BEGIN
	select 
		max(d.diseaseName) as diseaseName
		,sum(iif(pn.gender = 'male', 1, 0)) as male_cnt
		,sum(iif(pn.gender = 'female', 1, 0)) as femal_cnt
		,iif(sum(iif(pn.gender = 'male', 1, 0)) > sum(iif(pn.gender = 'female', 1, 0)),
			'male',
			iif((sum(iif(pn.gender = 'male', 1, 0)) < sum(iif(pn.gender = 'female', 1, 0))),
			'female',
			'same'
			)
		) as 'more_treated_gender'
	from Disease d
	join Treatment t on t.diseaseID = d.diseaseID
	join Patient p on p.patientID = t.patientID
	join Person pn on pn.personID = p.patientID
	where d.diseaseID = @diseaseID
END

exec get_gender_cnt 100;

-- Problem 3
with cte as
(select
	ip.planName
	,ic.companyName
	,count(c.claimID) as claim_cnt
from InsuranceCompany ic
join InsurancePlan ip on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
group by ip.planName, ic.companyName)
,cte1 as
(select top 3
	planName
	,companyName
	,claim_cnt
	,'most' as status
from cte
order by claim_cnt desc)
,cte2 as
(select top 3
	planName
	,companyName
	,claim_cnt
	,'least' as status
from cte
order by claim_cnt )
select * from cte1
union
select * from cte2;


-- Problem 4
with cte as
(select
	CASE
		WHEN pt.dob >= '2005-01-01' AND gender = 'Male' THEN 'YoungMale'
		WHEN pt.dob >= '2005-01-01' AND gender = 'Female' THEN 'YoungFemale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Male' THEN 'AdultMale'
		WHEN pt.dob < '2005-01-01' AND pt.dob >= '1985-01-01' AND gender = 'Female' THEN 'AdultFemale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Male' THEN 'MidAgeMale'
		WHEN pt.dob < '1985-01-01' AND pt.dob >= '1970-01-01' AND gender = 'Female' THEN 'MidAgeFemale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Male' THEN 'ElderMale'
		WHEN pt.dob < '1970-01-01' AND gender = 'Female' THEN 'ElderFemale'
		ELSE 'Unknown'
	END as category
	,d.diseaseName
from Patient pt
join Person p on p.personID = pt.patientID
join Treatment t on t.patientID = pt.patientID
join Disease d on d.diseaseID = t.diseaseID
)
,cte1 as
(select 
	category
	,diseaseName
	,count(diseaseName) as dis_per_cat
	,row_number() over(partition by diseaseName order by count(diseaseName) desc) as rnk
from cte
group by diseaseName, category)
select 
	diseaseName
	,category
	,dis_per_cat
from cte1
where rnk = 1;


-- Problem 5
with cte as
(select
	p.pharmacyName
	,m.productName
	,m.description
	,m.maxPrice
	,case
		when  maxPrice > 1000 then 'priecy'
		when  maxPrice < 5 then 'affordable'
		else 'mid'
	end as product_category
from Pharmacy p
join Keep k on k.pharmacyID = p.pharmacyID
join Medicine m on m.medicineID = k.medicineID)
select *
from cte
where product_category != 'mid'
order by maxPrice desc;

-- Section 8

-- Problem 1
-- For each age(in years), how many patients have gone for treatment?

-- Optimized Query
-- Changed * to patientID
-- Ans 1
-- Using YEAR in DATEDIFF instead of hour
SELECT 
	DATEDIFF(year, dob , GETDATE()) AS age, 
	count(Treatment.patientID) AS numTreatments
FROM Person
JOIN Patient ON Patient.patientID = Person.personID
JOIN Treatment ON Treatment.patientID = Patient.patientID
group by DATEDIFF(year, dob , GETDATE())
order by numTreatments desc;

-- Ans 2
-- Tried to avoid date func in groupBy
with cte as
(SELECT 
	DATEDIFF(year, dob , GETDATE()) AS age, 
	1 as cnt
FROM Person
JOIN Patient ON Patient.patientID = Person.personID
JOIN Treatment ON Treatment.patientID = Patient.patientID
)
select
	age
	,sum(cnt) AS numTreatments
from cte
group by age
order by numTreatments desc;


-- Problem 2
-- For each city, Find the number of registered people, number of pharmacies, and number of insurance companies.
select
	a.city
	,count(pn.personID) as numRegisteredPeople
	,count(p.pharmacyID) as numInsuranceCompany
	,count(ic.companyID) as numPharmacy
from Address a
full join Pharmacy p on p.addressID = a.addressID
full join InsuranceCompany ic on ic.addressID = a.addressID
full join Person pn on pn.addressID = a.addressID
group by a.city;


-- Problem 3
-- Total quantity of medicine for each prescription prescribed by Ally Scripts
-- If the total quantity of medicine is less than 20 tag it as "Low Quantity".
-- If the total quantity of medicine is from 20 to 49 (both numbers including) tag it as "Medium Quantity".
-- If the quantity is more than equal to 50 then tag it as "High quantity".

-- In previous we are using sum in very case statement multiple time, hence tried to minimize use of CASE statement
with cte as
(select 
	P.prescriptionID, 
	sum(quantity) as totalQuantity
FROM Contain C
JOIN Prescription P on P.prescriptionID = C.prescriptionID
JOIN Pharmacy on Pharmacy.pharmacyID = P.pharmacyID
where Pharmacy.pharmacyName = 'Ally Scripts'
group by P.prescriptionID)
select
	prescriptionID
	,totalQuantity
	,CASE 
		WHEN totalQuantity < 20 THEN 'Low Quantity'
		WHEN totalQuantity < 50 THEN 'Medium Quantity'
		ELSE 'High Quantity' 
	END AS Tag
from cte;


-- Problem 4
-- The total quantity of medicine in a prescription is the sum of the quantity of all the medicines in the prescription.
-- Select the prescriptions for which the total quantity of medicine exceeds
-- the avg of the total quantity of medicines for all the prescriptions.

-- The question aked is Prescription who exceed avg medicine quantity in single prescripotion
-- So I neglected Pharmacy join and used CTE and avoid creating a new table
with cte as
(select  Prescription.prescriptionID, sum(quantity) as totalQuantity
from Prescription
join Contain on Contain.prescriptionID = Prescription.prescriptionID
join Medicine on Medicine.medicineID = Contain.medicineID
join Treatment on Treatment.treatmentID = Prescription.treatmentID
where YEAR(date) = 2022
group by Prescription.prescriptionID)
select
	prescriptionID
	,totalQuantity
from cte
where totalQuantity > (select avg(totalQuantity) from cte)

-- Problem 5

-- Select every disease that has 'p' in its name, and 
-- the number of times an insurance claim was made for each of them. 

-- To count Claim ID we only need Treatment table
-- Joining Disease table for name check, and changed the where condition by removing sub-query

SELECT Disease.diseaseName, COUNT(Treatment.claimID) as numClaims
FROM Disease
JOIN Treatment ON Disease.diseaseID = Treatment.diseaseID
WHERE diseaseName LIKE '%p%'
GROUP BY diseaseName;


-- Section 10

-- Problem 1
drop procedure if exists plan_perf_report;
create procedure plan_perf_report(@companyID int)
as
begin
	with cte as
	(select
		ip.planName
		,ic.companyName
		,d.diseaseName
		,count(d.diseaseName) as dis_cnt
		,rank() over(partition by ip.planName order by count(d.diseaseName) desc) as rnk
	from InsurancePlan ip 
	join InsuranceCompany ic on ic.companyID = ip.companyID
	join Claim c on c.uin = ip.uin
	join Treatment t on t.claimID = c.claimID
	join Disease d on d.diseaseID = t.diseaseID
	where ic.companyID = @companyID
	group by ip.planName, ic.companyName, d.diseaseName)
	,cte1 as
	(select
		planName
		,companyName
		,diseaseName
	from cte
	where rnk = 1)
	,cte2 as
	(select 
		planName
		,companyName
		,sum(dis_cnt) as claim_cnt
	from cte
	group by planName, companyName)
	select distinct
		cte1.planName
		,cte1.companyName
		,diseaseName as highest_claimed_disease
		,claim_cnt
	from cte1
	join cte2 on cte1.planName = cte2.planName
	order by claim_cnt desc
end;

exec plan_perf_report 1118;

-- Problem 2
drop procedure get_disease_phar_report;

create procedure get_disease_phar_report(@diseaseName varchar(50))
as
begin
	with cte as
	(select 
		s.pharmacyName
		,year(t.date) as year
		,count(s.pharmacyID) as pharm_cnt
		,row_number() over(partition by year(t.date) order by count(s.pharmacyID)) as min_rnk
		,row_number() over(partition by year(t.date) order by count(s.pharmacyID) desc) as max_rnk
	from Disease d
	join Treatment t on t.diseaseID = d.diseaseID
	join Prescription p on p.treatmentID = t.treatmentID
	join Pharmacy s on s.pharmacyID = p.pharmacyID
	where d.diseaseName = @diseaseName
	and year(t.date) in (2021, 2022)
	group by s.pharmacyName, year(t.date))
	select 
		c1.pharmacyName as '2021_pharm'
		,c1.pharm_cnt
		,c2.pharmacyName as '2022_pharm'
		,c2.pharm_cnt
	from cte c1
	join cte c2 on c1.max_rnk = c2.max_rnk 
	and (c1.max_rnk <= 3 and c2.max_rnk <= 3) 
	and (c1.year = 2021 and c2.year = 2022)
end;

exec get_disease_phar_report Asthma;
exec get_disease_phar_report Psoriasis;


-- Problem 3
create procedure get_insurance_state_repoty
as
begin
	with cte as
	(select 
		a.state
		,count(ic.companyID) as company_cnt
		,count(p.patientID) as patient_cnt
		,iif( count(ic.companyID) > 0, count(p.patientID) * 1.0 / count(ic.companyID), 0) as patient_comp_ratio
		,avg(iif( count(ic.companyID) > 0, count(p.patientID) * 1.0 / count(ic.companyID), 0)) over() as avg_ratio
	from Address a
	full join InsuranceCompany ic on ic.addressID = a.addressID
	full join Person pn on pn.addressID = a.addressID
	full join Patient p on p.patientID = pn.personID
	group by a.state)
	select 
		state
		,company_cnt
		,patient_cnt
		,patient_comp_ratio
		,avg_ratio
		,case
			when patient_comp_ratio < avg_ratio then 'Recommended'
			else 'Not Recommended'
		end as status
	from cte
end;

exec get_insurance_state_repoty;

-- Problem 4

drop table if exists PlacesAdded;

create table PlacesAdded(
	placeID int identity(1, 1) primary key,
	placeName varchar(40),
	placeType varchar(10),
	timeAdded datetime
);

drop trigger if exists PlacesAddedTgr;

create trigger PlacesAddedTgr
on dbo.Address
for insert
as
begin
	
	if (select count(city) from Address i where city=(select city from inserted)) = 1
		insert into PlacesAdded(
			placeName,
			placeType,
			timeAdded
		)
		select 
			city,
			'city',
			getdate()
		from inserted
	if (select count(state) from Address i where state=(select state from inserted)) = 1
		insert into PlacesAdded(
			placeName,
			placeType,
			timeAdded
		)
		select 
			state,
			'state',
			getdate()
		from inserted
end;


-- Problem 5
drop table if exists Keep_log;

create table keep_log(
	id int NOT NULL IDENTITY(1,1),
	quantity int,
);

drop trigger if exists KeepLogTgr;
create trigger KeepLogTgr
on dbo.Keep
for update
as
	if update(quantity)
		insert into keep_log(quantity)
		select i.quantity - d.quantity
		from inserted i 
		join deleted d on i.pharmacyID = d.pharmacyID and i.medicineID = d.medicineID
;

-- Section 11

-- Problem 1
drop procedure if exists get_medicine_prod_details;

create procedure get_medicine_prod_details(@productName varchar(50))
as
select
	p.pharmacyName
	,p.phone
	,m.productName
	,k.quantity
from Pharmacy p
join Keep k on k.pharmacyID = p.pharmacyID
join Medicine m on m.medicineID = k.medicineID
where m.productName = @productName ;

exec get_medicine_prod_details MEGASTROL;

-- Problem 2
drop procedure if exists get_avg_med_per_prescription;

create procedure get_avg_med_per_prescription(@year int, @pharmacyID int)
as
	with cte as
	(select
		p.prescriptionID
		,sum(c.quantity * m.maxPrice) as total_cost_per_prescription
	from Prescription p
	join Treatment  t on t.treatmentID = p.treatmentID
	join Pharmacy s on s.pharmacyID = p.pharmacyID
	join Contain c on c.prescriptionID = p.prescriptionID
	join Medicine m on m.medicineID = c.medicineID
	where year(t.date) = @year
	and s.pharmacyID = @pharmacyID
	group by p.prescriptionID)
	select 
		avg(total_cost_per_prescription) as avg_med_per_prescription
	from cte
;

exec get_avg_med_per_prescription 2022, 7448;

-- Problem 3
drop procedure if exists get_most_disease_per_state;

create procedure get_most_disease_per_state(@state varchar(4), @year int)
as
select top 1
	d.diseaseName
	,count(t.treatmentID) as treatment_cnt
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where year(t.date) = @year
and a.state = @state
group by d.diseaseName
order by treatment_cnt desc;

exec get_most_disease_per_state CA, 2021;


-- Problem 4
drop procedure if exists get_tratment_cnt_per_disease_year_city;

create procedure get_tratment_cnt_per_disease_year_city(@city varchar(20), @diseaseName varchar(20), @year int)
as
select
	count(t.treatmentID) as treatment_cnt
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where a.city = @city
and d.diseaseName = @diseaseName
and year(t.date) = @year;

exec get_tratment_cnt_per_disease_year_city Anchorage, 'Autism', 2019

-- Problem 5
drop procedure if exists get_avg_balance_per_year_company;

create procedure get_avg_balance_per_year_company(@companyName varchar(100), @year int)
as
select
	avg(c.balance) as avg_balance
from InsuranceCompany ic
join InsurancePlan ip on ic.companyID = ip.companyID
join Claim c on c.uin = ip.uin
join Treatment t on t.claimID = c.claimID
where year(t.date) = @year
and ic.companyName = @companyName;

exec get_avg_balance_per_year_company 'Kotak Mahindra General Insurance Co. Ltd.', 2020

-- Section 9

-- Problem 1

select
	a.state
	,pn.gender
	,count(p.patientID)
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where d.diseaseName = 'Autism'
group by 
grouping sets ((a.state), (pn.gender), (a.state, pn.gender))
order by a.state, pn.gender

-- Problem 2
select
	ip.planName
	,ic.companyName
	,year(t.date)
	,count(distinct c.claimID) as claim_cnt
	,count(t.treatmentID) as treatment_cnt
from InsuranceCompany ic
join InsurancePlan ip on ip.companyID = ic.companyID
join Claim c on c.uin = ip.uin
join Treatment t on t.claimID = c.claimID
group by
grouping sets ((year(t.date)), (ip.planName,ic.companyName), (year(t.date), ip.planName,ic.companyName))
order by ip.planName, ic.companyName, year(t.date);

-- Problem 4
select
	s.pharmacyName
	,d.diseaseName
	,count(p.prescriptionID) as pres_cnt
from Pharmacy s
join Prescription p on p.pharmacyID = s.pharmacyID
join Treatment t on t.treatmentID = p.treatmentID
join Disease d on d.diseaseID = t.diseaseID
where year(t.date) = 2021
group by grouping sets ((s.pharmacyName), (d.diseaseName), (s.pharmacyName, d.diseaseName))
order by s.pharmacyName, d.diseaseName;


-- Problem 5
select
	d.diseaseName
	,pn.gender
	,count(t.treatmentID) as treatment_cnt
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
where year(t.date) = 2022
group by cube(d.diseaseName, pn.gender);



-- Problem 3
with cte as afff
(select
	a.state
	,d.diseaseName
	,count(t.treatmentID) as treatment_cnt
from Disease d
join Treatment t on t.diseaseID = d.diseaseID
join Patient p on p.patientID = t.patientID
join Person pn on pn.personID = p.patientID
join Address a on a.addressID = pn.addressID
where year(t.date) = 2022
group by a.state, d.diseaseName)
,cte1 as
(select
	state
	,diseaseName
	,ROW_NUMBER() over(partition by state order by treatment_cnt desc) as max_rnk
	,ROW_NUMBER() over(partition by state order by treatment_cnt) as min_rnk
from cte)
select 
;

group by cube(state) 
