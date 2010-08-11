namespace demo.water

import System

/*************************************************************************
Bessel function of order zero

Returns Bessel function of order zero of the argument.

The domain is divided into the intervals [0, 5] and
(5, infinity). In the first interval the following rational
approximation is used:


       2         2
(w - r  ) (w - r  ) P (w) / Q (w)
      1         2    3       8

           2
where w = x  and the two r's are zeros of the function.

In the second interval, the Hankel asymptotic expansion
is employed with two rational functions of degree 6/6
and 7/7.

ACCURACY:

                     Absolute error:
arithmetic   domain     # trials      peak         rms
   IEEE      0, 30       60000       4.2e-16     1.1e-16

Cephes Math Library Release 2.8:  June, 2000
Copyright 1984, 1987, 1989, 2000 by Stephen L. Moshier
*************************************************************************/

public static class Bessel:
	public def J0(x as double) as double:
		x*=-1.0	if x<0.0
		if x>8.0:
			pzero = qzero = 0.0
			Asympt0(x, pzero, qzero)
			nn = x - 0.25*Math.PI
			d2 = pzero*Math.Cos(nn)-qzero*Math.Sin(nn)
			return Math.Sqrt(2 / Math.PI / x) * d2
		
		xsq = x * x
		p1 = 26857.86856980014981415848441
		p1 = -40504123.71833132706360663322	+xsq*p1
		p1 = 25071582855.36881945555156435	+xsq*p1
		p1 = -8085222034853.793871199468171	+xsq*p1
		p1 = 1434354939140344.111664316553	+xsq*p1
		p1 = -136762035308817138.6865416609	+xsq*p1
		p1 = 6382059341072356562.289432465	+xsq*p1
		p1 = -117915762910761053603.8440800	+xsq*p1
		p1 = 493378725179413356181.6813446	+xsq*p1
		q1 = 1.0
		q1 = 1363.063652328970604442810507	+xsq*q1
		q1 = 1114636.098462985378182402543	+xsq*q1
		q1 = 669998767.2982239671814028660	+xsq*q1
		q1 = 312304311494.1213172572469442	+xsq*q1
		q1 = 112775673967979.8507056031594	+xsq*q1
		q1 = 30246356167094626.98627330784	+xsq*q1
		q1 = 5428918384092285160.200195092	+xsq*q1
		q1 = 493378725179413356211.3278438	+xsq*q1
		return (p1 / q1)
	
	private def Asympt0(x as double, ref pzero as double, ref qzero as double) as void:
		xsq = 64.0 / (x*x)
		p2 = 0.0
		p2 = 2485.271928957404011288128951	+xsq*p2
		p2 = 153982.6532623911470917825993	+xsq*p2
		p2 = 2016135.283049983642487182349	+xsq*p2
		p2 = 8413041.456550439208464315611	+xsq*p2
		p2 = 12332384.76817638145232406055	+xsq*p2
		p2 = 5393485.083869438325262122897	+xsq*p2
		q2 = 1.0
		q2 = 2615.700736920839685159081813	+xsq*q2
		q2 = 156001.7276940030940592769933	+xsq*q2
		q2 = 2025066.801570134013891035236	+xsq*q2
		q2 = 8426449.050629797331554404810	+xsq*q2
		q2 = 12338310.22786324960844856182	+xsq*q2
		q2 = 5393485.083869438325560444960	+xsq*q2
		p3 = -0.0
		p3 = -4.887199395841261531199129300	+xsq*p3
		p3 = -226.2630641933704113967255053	+xsq*p3
		p3 = -2365.956170779108192723612816	+xsq*p3
		p3 = -8239.066313485606568803548860	+xsq*p3
		p3 = -10381.41698748464093880530341	+xsq*p3
		p3 = -3984.617357595222463506790588	+xsq*p3
		q3 = 1.0
		q3 = 408.7714673983499223402830260	+xsq*q3
		q3 = 15704.89191515395519392882766	+xsq*q3
		q3 = 156021.3206679291652539287109	+xsq*q3
		q3 = 533291.3634216897168722255057	+xsq*q3
		q3 = 666745.4239319826986004038103	+xsq*q3
		q3 = 255015.5108860942382983170882	+xsq*q3
		pzero = p2 / q2
		qzero = 8.0*p3 / q3 / x
