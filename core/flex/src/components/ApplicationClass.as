package components
{
	// Code behind for FlashFileUpload.mxml
	import flash.events.*;
	import flash.external.*;
	import flash.net.FileFilter;
	import flash.net.FileReferenceList;
	import flash.utils.Timer;
	
	import mx.containers.*;
	import mx.controls.*;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;

	public class ApplicationClass extends Application
	{
		private var fileRefList:FileReferenceList;
		private var fileRefListener:Object;
		private var _filenameMaxLength:Number;
		private var _totalSize:Number;
		private var _uploadedBytes:Number;
		private var _currentUpload:FileUpload;
		private var _uploadFileSize:Number;
		private var _totalUploadSize:Number;
		private var _fileMaxNumber:Number;
		private var _fileTypeDescription:String;
		private var _fileTypes:String;
		private var _currentFolderFiles:Array;
		private var jsReady:Boolean;
		private var limitsText:Object;
		
		// all controls in the mxml file must be public variables in the code behind
		public var fileContainer:VBox;
		public var fileUploadBox:VBox;
		public var uploadStats:HBox;
		public var totalFiles:Text;
		public var totalSize:Text;
		public var totalText:Text;
		public var sizeText:Text;
		public var totalProgressBar:ProgressBar;
		public var browseButton:Button;
		public var clearButton:Button;
		public var uploadButton:Button;
		public var cancelButton:Button;
		public var optionButton:Button;
		public var closeButton:Button;
		public var spacer:Spacer;
		
		public var autoUpload:Boolean;		
		
		
		// constructor
		public function ApplicationClass()
		{
			super();
			addEventListener (FlexEvent.CREATION_COMPLETE, OnLoad);
		}
		
		private function OnLoad(event:Event):void{
			// instantiate and initialize variables
			fileRefList = new FileReferenceList();
			_totalSize = 0;
			_uploadedBytes = 0;
			jsReady = false;
			intializeExternalComm();			
			
			// hook up our event listeners
			fileRefList.addEventListener(Event.SELECT,OnSelect);
			browseButton.addEventListener(MouseEvent.CLICK,OnAddFilesClicked);
			clearButton.addEventListener(MouseEvent.CLICK,OnClearFilesClicked);
			uploadButton.addEventListener(MouseEvent.CLICK,OnUploadFilesClicked);
			cancelButton.addEventListener(MouseEvent.CLICK,OnCancelClicked);
			optionButton.addEventListener(MouseEvent.CLICK,OnOptionsClicked);
			closeButton.addEventListener(MouseEvent.CLICK,OnCloseClicked);
			
			limitsText = new Object();
			var limitString:String = GetTextFor("UploadLimitsTitle")+"<br>";
			var limitSet:Boolean = false;
			var temp:String = Application.application.parameters.fileSizeLimit;
			if(temp != null && temp != ""){
			    _uploadFileSize = new Number(temp);
			    if(_uploadFileSize != 0){
				    limitString = limitString + GetTextFor("UploadLimitsSizePerFile")+": " + FileUpload.FormatSize(_uploadFileSize, "B") + "<br>";
				    limitsText[GetTextFor("UploadLimitsSizePerFile")] = FileUpload.FormatSize(_uploadFileSize, "B");
				    limitSet = true;
				}
			}else
			    _uploadFileSize = 0;
			    
			temp = Application.application.parameters.totalUploadSize;
			if(temp != null && temp != ""){
			    _totalUploadSize = new Number(temp);
			    if(_totalUploadSize != 0){
				    limitString = limitString + GetTextFor("UploadLimitsTotalSize")+": " + FileUpload.FormatSize(_totalUploadSize, "B") + "<br>";
				    limitsText[GetTextFor("UploadLimitsTotalSize")] = FileUpload.FormatSize(_totalUploadSize, "B");
				    limitSet = true;
			    }
			}else
			    _totalUploadSize = 0;
			 
			temp = Application.application.parameters.maxFileNumber;
			if(temp != null && temp != ""){
			    _fileMaxNumber = new Number(temp);
			    if(_fileMaxNumber != 0){
				    limitString = limitString + GetTextFor("UploadLimitsFilesNumber")+": " + _fileMaxNumber + "<br>";
				    limitsText[GetTextFor("UploadLimitsFilesNumber")] = _fileMaxNumber;
				    limitSet = true;
			    }			    
			}else
			    _fileMaxNumber = 0;
			 
			 temp = Application.application.parameters.currentFolderFiles;
			 var tempSep:String = Application.application.parameters.separator;
			 if(temp != null && temp != "" && tempSep != null && tempSep != ""){
			 	_currentFolderFiles = temp.split(tempSep);
			 }else{
			 	_currentFolderFiles = new Array();
			 }
			  
			temp = Application.application.parameters.maxFilenameLength;
			if(temp != null && temp != ""){
			    _filenameMaxLength = new Number(temp);
			}else
			    _filenameMaxLength = 0;
			 
			    
			_fileTypeDescription = Application.application.parameters.fileTypeDescription;
			_fileTypes = Application.application.parameters.fileTypes;
			
			browseButton.label = GetTextFor("Add");
			clearButton.toolTip = GetTextFor("Clear");
			uploadButton.toolTip = GetTextFor("Upload");
			cancelButton.toolTip = GetTextFor("Cancel");
			totalText.text = GetTextFor("TotalFile");
			sizeText.text = GetTextFor("SizeText");
			closeButton.label = GetTextFor("CloseText");
			optionButton.label = GetTextFor("OptionsText");
			
			LoadAutoUpload();			
		}
		
		private function intializeExternalComm():void{
		    // Check if the container is able to use the external API.
		    if (ExternalInterface.available){
		        try{
		            var containerReady:Boolean = isContainerReady();
		            if (containerReady){
		                setupCallbacks();
		            }else{
		                var readyTimer:Timer = new Timer(100);
		                readyTimer.addEventListener(TimerEvent.TIMER, timerHandler);
		                readyTimer.start();
		            }
		        }catch(e:Error){
		        	Alert.show(e.message);
		        }
		    }else{
		        trace("External interface is not available for this container.");
		    }			
		}
		
		private function isContainerReady():Boolean
		{
		    var result:Boolean = ExternalInterface.call("isReady");
		    return result;
		}
		
		private function timerHandler(event:TimerEvent):void
		{
		    var isReady:Boolean = isContainerReady();
		    if (isReady)
		    {
		        Timer(event.target).stop();
		        setupCallbacks();
		    }
		}
		
		private function setupCallbacks():void{
			jsReady = true;
		}
		
		private function triggerJSEvent(eventType:String):*{
			if(jsReady){				
				return ExternalInterface.call("triggerFlashEvent", eventType);
			}else{
				//Alert.show("Not ready");
			}
		}
		
		private function OnCloseClicked(event:Event):void{
			triggerJSEvent("closeModal");
		}
		
		private function OnOptionsClicked(event:Event):void{
			var optionsPane:OptionsPane = OptionsPane(PopUpManager.createPopUp(this, OptionsPane, true));
			optionsPane.setLabels(limitsText, autoUpload); 
		}
		
		// brings up file browse dialog when add file button is pressed
		private function OnAddFilesClicked(event:Event):void{
		
			if(_fileTypes != null && _fileTypes != "")	
			{
			    if(_fileTypeDescription == null || _fileTypeDescription == "")
			        _fileTypeDescription = _fileTypes;
			        
			    var filter:FileFilter = new FileFilter(_fileTypeDescription, _fileTypes);
                
                fileRefList.browse([filter]);
			}
			else
			    fileRefList.browse();
			
		}
		
		// fires when the clear files button is clicked
		private function OnClearFilesClicked(event:Event):void{			
			// cancels an upload if there is a file being uploaded
			if(_currentUpload != null)
				_currentUpload.CancelUpload();
			// clears all the files
			fileUploadBox.removeAllChildren();
			// reset the labels
			SetLabels();
			// reinitialize the variables;
			_uploadedBytes = 0;
			_totalSize = 0;
			_currentUpload == null;
		}
		
		// fires when the upload upload button is clicked
		private function OnUploadFilesClicked(event:Event):void{
			// get all the files to upload
			var fileUploadArray:Array = fileUploadBox.getChildren();
			// initialize a helper boolean variable
			var fileUploading:Boolean = false;			
			_currentUpload = null;							
			
			// set the button visibility
			uploadButton.enabled = false;
			// browseButton.enabled = false;
			clearButton.enabled = false;
			cancelButton.enabled = true;
			// go through the files to check if they have been uploaded and get the first that hasn't
			for(var x:uint=0;x<fileUploadArray.length;x++)
			{
				// find a file that hasn't been uploaded and start it
				if(!FileUpload(fileUploadArray[x]).IsUploaded)
				{
					fileUploading = true;
					// set the current upload and start the upload
					_currentUpload = FileUpload(fileUploadArray[x]);
					_currentUpload.Upload();
					break;
				}
			}	
			// if all files have been uploaded
			if(!fileUploading)
			{
				OnCancelClicked(null);
				triggerJSEvent("uploadComplete");
			}
		}
		
		// fired when the cancel button is clicked
		private function OnCancelClicked(event:Event):void{
			// if there is a file being uploaded then cancel it and adjust the uploaded bytes variable to reflect the cancel
			if(_currentUpload != null)
			{
				_currentUpload.CancelUpload();
				_uploadedBytes -= _currentUpload.BytesUploaded;
				_currentUpload = null;					
			}
			// reset the labels and set the button visibility
			SetLabels();
			uploadButton.enabled = true;
			browseButton.enabled = true;
			clearButton.enabled = true;
			cancelButton.enabled = false;
		}
		
		// fired when files have been selected in the file browse dialog
		private function OnSelect(event:Event):void{
			// get the page to upload to, set in flashvars
			var uploadPage:String = Application.application.parameters.uploadPage;
			//uploadPage += "&dir="+ triggerJSEvent("currentFolder");
            var dir:String = triggerJSEvent("currentFolder");
			
			var tempSize:Number = _totalSize;
			
			var fileUploadArray:Array = fileUploadBox.getChildren();			
			
			var tempNumber:Number = fileUploadArray.length;
			var foundExisting:Boolean = false;
			
			// add each file that was selected
			for(var i:uint=0;i<fileRefList.fileList.length;i++)
			{
				// Check the file is not already in the list!
				var fileName:String = String(fileRefList.fileList[i].name).toLowerCase();
				var foundSame:Boolean = false;
				for(var j:uint=0;j<fileUploadArray.length;j++){
					if(fileName == FileUpload(fileUploadArray[j]).getFileName().toLowerCase() ) {
						foundSame = true;
						break;					
					}
				}
				if(foundSame) {
					continue;
				}
				if(fileName.length > _filenameMaxLength){
					this.OnFilenameMaxLengthReached();
				}
				var localFoundExisting:Boolean = false;
				try{
					var _crtFilesString:String = triggerJSEvent("currentFiles").toString();
					if(_crtFilesString != null){
						_currentFolderFiles = _crtFilesString.split("__AJXP_SEP__");
					}
					for(j=0;j<_currentFolderFiles.length;j++){
						if(fileName == String(_currentFolderFiles[j]).toLocaleLowerCase()){
							foundExisting = true;
							localFoundExisting = true;
							break;
						}
					}				
				}catch(e:Error){
					Alert.show(e.message);
				}
				
				// create new FileUpload and add handlers then add it to the fileuploadbox
				if(_uploadFileSize > 0 && fileRefList.fileList[i].size > _uploadFileSize){
				    OnFileSizeLimitReached(fileRefList.fileList[i].name);
				    continue;
				}
				if(_totalUploadSize > 0 && tempSize + fileRefList.fileList[i].size > _totalUploadSize)
				{
				    OnTotalFileSizeLimitReached();
				    break;
				}
				
				if(_fileMaxNumber > 0 && tempNumber + 1 > _fileMaxNumber){
					OnFileMaxNumberReached();
					break;
				}
				
				if((_uploadFileSize == 0 || fileRefList.fileList[i].size < _uploadFileSize) && (_totalUploadSize == 0 || tempSize + fileRefList.fileList[i].size < _totalUploadSize))
				{
				    var fu:FileUpload = new FileUpload(fileRefList.fileList[i],uploadPage, GetTextFor("Uploaded"), GetTextFor("Remove"), GetTextFor("Byte"), this['RemoveIcon']);					
				    fu.percentWidth = 100;				
                    fu.dir = dir;
				    fu.addEventListener("FileRemoved",OnFileRemoved);	
				    fu.addEventListener("UploadComplete",OnFileUploadComplete);
				    fu.addEventListener("UploadProgressChanged",OnFileUploadProgressChanged);
				    fu.addEventListener(HTTPStatusEvent.HTTP_STATUS,OnHttpError);
				    fu.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,OnUploadDataComplete);
				    fu.addEventListener(IOErrorEvent.IO_ERROR,OnIOError);
				    fu.addEventListener(SecurityErrorEvent.SECURITY_ERROR,OnSecurityError);
				    if(localFoundExisting){
				    	fu.setAlreadyExists();
				    }
				    fileUploadBox.addChild(fu);	
				    tempSize += fileRefList.fileList[i].size;
				    tempNumber ++;	
				}			
			}
			if(foundExisting){
				OnFileAlreadyExistingFound();
				SetLabels();
			}else{
				SetLabels();
				if(autoUpload){						
					OnUploadFilesClicked(null);
				}
			}
			
		}
		
		// fired when a the remove file button is clicked
		private function OnFileRemoved(event:FileUploadEvent):void{
			_uploadedBytes -= FileUpload(event.Sender).BytesUploaded;
			fileUploadBox.removeChild(FileUpload(event.Sender));				
			SetLabels();
			if(_currentUpload == FileUpload(event.Sender))
				OnUploadFilesClicked(null);
		}
		
		// fired when a file has finished uploading
		private function OnFileUploadComplete(event:FileUploadEvent):void{
			_currentUpload == null;
			OnUploadFilesClicked(null);
		}
				
		public function GetTextFor(text:String):String{
			if(jsReady){
				return ExternalInterface.call("triggerFlashEvent", "getMessage", text);
			}else{
				return text;
			}
		}
		
		private function OnTotalFileSizeLimitReached():void{
		    Alert.show(GetTextFor("MaxFilesSizeLimit"));
		}
		
		private function OnFileMaxNumberReached():void{
			Alert.show(GetTextFor("MaxFilesNumber"));
		}
		
		private function OnFilenameMaxLengthReached():void{
			Alert.show(GetTextFor("FilenamesMaxLengthWarning").replace("%s", _filenameMaxLength));
		}		
		
		private function OnFileSizeLimitReached(fileName:String):void{
		    Alert.show(GetTextFor("MaxFileSize") + " : " + fileName);
		}
		
		private function OnFileAlreadyExistingFound():void{
			Alert.buttonWidth = 100;
			Alert.yesLabel = GetTextFor("overwrite");
			Alert.noLabel = GetTextFor("skip");
			Alert.cancelLabel = GetTextFor("rename");
			Alert.show(GetTextFor("existingFilesFound"), "", 1|2|8, this, alertClickHandler);
		}
		
		private function alertClickHandler(event:CloseEvent):void{
			var fUploads:Array = fileUploadBox.getChildren();
			var i:uint=0;
			var crtFU:FileUpload;
			if(event.detail == Alert.NO){
				// Purge existing files from list!
				for(i=0;i<fUploads.length;i++){
					crtFU = FileUpload(fUploads[i]);
					if(crtFU.alreadyExists()){
						fileUploadBox.removeChild(crtFU);
						SetLabels();
					}
				}
			}else if(event.detail == Alert.CANCEL){
				// Set Rename flag
				for(i=0;i<fUploads.length;i++){
					crtFU = FileUpload(fUploads[i]);
					if(crtFU.alreadyExists()){
						crtFU.setRename();
					}
				}				
			}else if(event.detail == Alert.YES){
				// Do nothing, files will be overwritten
			}
			Alert.yesLabel = "OK";
			Alert.noLabel = "Cancel";
			if(autoUpload){
				OnUploadFilesClicked(null);
			}
		}
		
		public function ChangeAutoUpload(newValue:Boolean):void{
			autoUpload = newValue;
			uploadButton.setVisible(!newValue);
			uploadButton.height = (newValue?0:32);
			spacer.height = (newValue?102+32:102);
			if(jsReady){
				ExternalInterface.call("triggerFlashEvent", "storeProperty", "autoUpload", String(newValue) );
			}
		}
		
		public function LoadAutoUpload():void{
			if(jsReady){
				var value:Object = ExternalInterface.call("triggerFlashEvent", "getProperty", "autoUpload");
				if(value == null){
					autoUpload = true;
				}else{
					autoUpload = Boolean(value);
				}
			}
			uploadButton.setVisible(!autoUpload);	
			uploadButton.height = (autoUpload?0:32);
			spacer.height = (autoUpload?102+32:102);		
		}
		
		//  error handlers
		private function OnUploadDataComplete(event:DataEvent):void{
			Alert.show(GetTextFor("IOError") + " " + event.data);
		}
		//  error handlers
		private function OnHttpError(event:HTTPStatusEvent):void{
			Alert.show(GetTextFor("HTTPError") + event.status);
		}
		private function OnIOError(event:IOErrorEvent):void{
			Alert.show(GetTextFor("IOError") + event.text);
		}
		
		private function OnSecurityError(event:SecurityErrorEvent):void{
			Alert.show(GetTextFor("SecurityError") + event.text);
		}
		
		// fired when upload progress changes
		private function OnFileUploadProgressChanged(event:FileUploadProgressChangedEvent):void{
			_uploadedBytes += event.BytesUploaded;	
			SetProgressBar();
		}
		
		// sets the progress bar and label
		private function SetProgressBar():void{
			totalProgressBar.setProgress(_uploadedBytes,_totalSize);			
			totalProgressBar.label = GetTextFor("Uploaded") + " " + FileUpload.FormatPercent(totalProgressBar.percentComplete) + "% - " 
				+ FileUpload.FormatSize(_uploadedBytes, GetTextFor("Byte")) + " / " + FileUpload.FormatSize(_totalSize, GetTextFor("Byte"));
		}
		
		// sets the labels
		private function SetLabels():void{
			var fileUploadArray:Array = fileUploadBox.getChildren();
			if(fileUploadArray.length > 0)
			{
				totalFiles.text = String(fileUploadArray.length);
				_totalSize = 0;
				for(var x:uint=0;x<fileUploadArray.length;x++)
				{
					_totalSize += FileUpload(fileUploadArray[x]).FileSize;
				}
				totalSize.text = FileUpload.FormatSize(_totalSize, GetTextFor("Byte"));
				SetProgressBar();
				clearButton.enabled = uploadButton.enabled = true;					
			}
			else
			{
				totalFiles.text = String(0);
				_totalSize = 0;
				totalSize.text = FileUpload.FormatSize(_totalSize, GetTextFor("Byte"));
				SetProgressBar();
				clearButton.enabled = uploadButton.enabled = false;					
			}
		}	
	}
}