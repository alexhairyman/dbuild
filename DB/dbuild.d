module DB.dbuild;

private import DB.dpackage;
private import DB.util;

/**
 * takes packages and does stuff with them
 */
class DBuild
{
private:
  DFront compiler_front_;
  string compiler_;
  string args_; /// contains list of arguments
  string files_; /// contains master list of files
  DPackage[string] packs_; /// contains the packages and their names
  string[][string] pdeps_;
  string inc_,hdir_,odir_,ldir_,lib_;
  
  void InitSwitches();
  
public:
  this(DFront compiler)
  {
    if(compiler == DFront.dmd)
      compiler_ = "dmd";
  }
  
  /**
   * adds a dependency for p1 to p2
   */
   void AddDepends(string p1, string p2)
   {
     if(PackExists(p1) && PackExists(p2))
     {
       pdeps_[p1] ~= p2;
     }
   }
   
   /**
    * get dependencies of the package
    */
   string[] GetDepends(string packagename)
   {
     string[] tstrarr;
     if(PackExists(packagename))
     {
       tstrarr = pdeps_[packagename];
     }
     return tstrarr;
   }
  
  /**
   * Adds a package with a string, so it can be built by name
   * Params:
   *  called= the name to call the package
   *  p= Package to add
   */
  void AddPackage(DPackage p, string called)
  {
    if ((called in packs_) is null)
    {
      packs_[called] = p;
      pdeps_[called] ~= null;
    }
  }
  
  /**
   * Get the package with the specified name
   */
  
  DPackage GetPackage(string packagename)
  {
    if (PackExists(packagename))
    {
      return packs_[packagename];
    }
    assert(0);
  }
  
  /**
   * Get package at the position specified $(B mostly for internal use)
   * $(GREEN $(B $(I Disabled because the array is an associative one )))
   * Disabled: It won't work.... ever
   */
  @disable DPackage GetPackage(uint index)
  {
    return null;
  }
  
  /**
   * Checks for package existence
   */
  bool PackExists(string packagename)
  {
    if ((packagename in packs_) is null)
      return false;
    else
      return true;
  }
  
  /**
   * Generate File List
   * Returns: string of all the files, spaced out
   */
  string GenFileList(string packagename)
  {
    string tstr;
    DPackage d = GetPackage(packagename);
    foreach (string s; d.GetFiles())
    {
      tstr ~= s ~ " ";
    }
    return tstr;
  }
  
  /**
   * Generates all the lib, include, etc arguments for the package
   * Returns: everything you will ever need to customize the build
   */
  string GenArgList(string packagename)
  {
    string tstr, outprefix;
    DPackage d = GetPackage(packagename);
    
    if(d.GetType() == DTarget.STATICLIB)
      tstr ~= "-lib ";
    else if(d.GetType() == DTarget.SHAREDLIB)
    {
      tstr ~= "-fPIC -shared ";
      outprefix = d.GetBuildDir ~ "/";
    }
    else if (d.GetType() == DTarget.EXECUTABLE)
    {
      outprefix = d.GetBuildDir ~ "/";
    }
      
    foreach(string s; d.GetIncludes())
    {
      tstr ~= "-I" ~ s ~ " ";
    }
    
    foreach(string s; d.GetLibDirs())
    {
      tstr ~= "-L-L" ~ s ~ " ";
    }
    
    foreach(string s; d.GetLibs())
    {
      tstr ~= "-L-l" ~ s ~ " ";
    }
    
    if(d.GetOutFile != null)
      tstr ~= "-of" ~ outprefix ~ d.GetOutFile() ~ " ";
    
    if(d.GetBuildDir != null)
      tstr ~= "-od" ~ d.GetBuildDir() ~ " ";
      
    if(d.GetHeaderDir != null)
      tstr ~= "-Hd" ~ d.GetHeaderDir() ~ " ";
    
    if(d.GetDocDir != null)
      tstr ~= "-Dd" ~ d.GetDocDir() ~ " ";
    
    if(d.IsObjectCollection == true)
      tstr ~= "-c ";
    
    foreach(string s; d.GetArgs())
    {
      tstr ~= s ~ " ";
    }
    
    return tstr;
  }
  
  /**
   * Get an array of all the necessary dependant command lines for a package
   */
  string[] CompileCommandLineDepends(string packagename, bool includetarget=true)
  {
    string[] deplines;
    
    if(pdeps_.length > 0 && PackExists(packagename))
    {
      while(1)
      {
        if (pdeps_[packagename].length > 0 && pdeps_[packagename].length -1 > deplines.length)
        {
          foreach(string s; GetDepends(packagename))
          {
            deplines ~= CompileCommandLineDepends(s, true);
          }
        }
        else if(pdeps_[packagename].length - 1 == deplines.length && includetarget)
        {
          deplines ~= CompileCommandLine(packagename);
          break;
        }
      }
    }
    return deplines;
  }
  
  /**
   * Construct the command line necessary to build the package
   */
  string CompileCommandLine(string packagename)
  {
    string stemp;
    if (PackExists(packagename))
    {
      stemp ~= compiler_ ~ " " ~ this.GenFileList(packagename) ~ this.GenArgList(packagename);
    }
    return stemp;
  }
  
  /**
   * returns array of strings to compile all of the files individually
   */
  @disable string[] ObjectCompileLine(string packagename)
  {
    return null;
  }
  
  public void Build(DPackage p)
  {
    
  }
}
