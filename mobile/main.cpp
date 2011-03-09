#include "src\asset.h"
#include "src\core.h"
#include "src\scene.h"

int main()	{
	kri::Core core("");
	const kri::Pointer<kri::Scene> pScene =
		core.mResMan->loader3Ds.read("cube.3ds");
	return 0;
}