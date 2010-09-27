__author__ = ['Dzmitry Malyshau']
__bpydoc__ = 'Settings & Writing access for KRI exporter.'

class Settings:
	doQuatInt	= True
	putUv		= True
	putColor	= False
	logInfo		= True
	kFrameSec	= 1.0 / 25.0


class Writer:
	inst = None
	__slots__= 'fx','pos'
	def __init__(self,path):
		self.fx = open(path,'wb')
		self.pos = 0
	def pack(self,tip,*args):
		import struct
		assert self.pos
		self.fx.write( struct.pack('<'+tip,*args) )
	def array(self,tip,ar):
		import array
		assert self.pos
		array.array(tip,ar).tofile(self.fx)
	def text(self,*args):
		for s in args:
			n = len(s)
			assert n<256
			self.pack("B%ds"%(n), n,s)
	def begin(self,name):
		import struct
		assert len(name)<8 and not self.pos
		self.fx.write( struct.pack('<8sL',name,0) )
		self.pos = self.fx.tell()
	def end(self):
		import struct
		assert self.pos
		off = self.fx.tell() - self.pos
		self.fx.seek(-off-4,1)
		self.fx.write( struct.pack('<L',off) )
		self.fx.seek(+off+0,1)
		self.pos = 0


def save_color(rgb):
	for c in rgb:
		Writer.inst.pack('B', int(255*c) )


def save_matrix(mx):
	import math
	pos = mx.translation_part()
	sca = mx.scale_part()
	rot = mx.to_quat()
	scale = (sca.x + sca.y + sca.z)/3.0
	if math.fabs(sca.x-sca.y) + math.fabs(sca.x-sca.z) > 0.01:
		print("\t(w)",'non-uniform scale:',str(sca))
	Writer.inst.pack('8f',
		pos.x, pos.y, pos.z, scale,
		rot.x, rot.y, rot.z, rot.w )
