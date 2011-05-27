namespace kri.meta

import OpenTK
import kri.shade


public class Pass:
	public final	affects		= List[of string]()
	public prog		as Bundle	= null
	public enable		= true
	public blend		= ''
	public bumpSpace	= ''
	public color		= Graphics.Color4.White
	public defValue		= 1f
	public doIntensity	= false
	public doInvert		= false
	public doStencil	= false


#---	Unit Slave meta data	---#
public class AdUnit( ISlave, par.ValuePure[of kri.buf.Texture] ):
	public input	as Hermit	= null
	public final	pOffset		= par.ValuePure[of Vector4]()
	public final	pScale		= par.ValuePure[of Vector4]()
	portal Offset	as Vector4	= pOffset.Value
	portal Scale	as Vector4	= pScale.Value
	public final	layer		= Pass()
	
	public def constructor():
		pOffset	.Value = Vector4.Zero
		pScale	.Value = Vector4.One
	
	def System.ICloneable.Clone() as object:
		return AdUnit( Value:Value, input:input, Offset:Offset, Scale:Scale )
	
	def ISlave.link(name as string, d as par.Dict) as void:
		d.unit(name,self)
		d['offset_'	+name] = pOffset
		d['scale_'	+name] = pScale
