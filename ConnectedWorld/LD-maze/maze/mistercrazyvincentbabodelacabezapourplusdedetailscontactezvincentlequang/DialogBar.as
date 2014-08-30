package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextFieldType;
	import flash.text.TextField;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.events.TextEvent;
	import flash.text.TextFieldAutoSize;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.StyleSheet;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.geom.Rectangle;
	import flash.filters.ColorMatrixFilter;
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.FocusEvent;
	import flash.net.FileReference;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import com.adobe.images.PNGEncoder;
	import by.blooddy.crypto.MD5;
	import flash.media.Sound;
	
	
	public class DialogBar extends MovieClip {
		
		static const NUM_ANSWERS:int = 4;
		
		public var dialog:Object = null;
		public var binaryStore:Object = {};
		
		private var history:Array = [];
		private var loader:Loader = new Loader();
		private var file:FileReference;
		
		private var beep:Sound = new Beep();
		private var beep2:Sound = new Beep2();
		
		public function DialogBar():void {
			var dialog:Object =
			{
				dialogID:null,
				mode:"admin",
				dialog:[
					{
						id:"1",
						text:"What is your name?",
						answers:[
							{text:"Henry",next:"2"},
							{text:"John",next:"3"}
						]
					},
					{
						id:"2",
						text:"Hello Henry"
					},
					{
						id:"3",
						text:"Hello John"
					}
				]
			}
			initialize(dialog);
			for(var i:int=1;i<=NUM_ANSWERS;i++) {
				this["answer"+i].tf.addEventListener(MouseEvent.ROLL_OVER,onMouse);
				this["answer"+i].tf.addEventListener(MouseEvent.ROLL_OUT,onMouse);
				this["answer"+i].tf.addEventListener(MouseEvent.MOUSE_DOWN,onMouse);
				this["answer"+i].tf.addEventListener(MouseEvent.MOUSE_UP,onMouse);
				this["answer"+i].tf.addEventListener(KeyboardEvent.KEY_DOWN,onKey);
				this["answer"+i].del.addEventListener(MouseEvent.CLICK,onDelete);
				this["answer"+i].edit.addEventListener(MouseEvent.CLICK,onEditChunk);
//				this["answer"+i].item.addEventListener(MouseEvent.CLICK,onItem);
			}
			addAnswer.addEventListener(MouseEvent.CLICK,onAddAnswer);
			selectItemPopup.visible = false;
			answerPopup.visible = false;
//			selectDialogPopup.tf.autoSize = TextFieldAutoSize.LEFT;
			
			tf.addEventListener(KeyboardEvent.KEY_DOWN,onKeyMain);
			tf.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,onFocusOut);
			tf.addEventListener(MouseEvent.MOUSE_DOWN,onEdit);
			edit.addEventListener(MouseEvent.CLICK,onEdit);
			info.addEventListener(MouseEvent.CLICK,onInfo);
			infoPopup.addEventListener(MouseEvent.CLICK,onInfo);
			backButton.addEventListener(MouseEvent.CLICK,onBack);
			profile.addEventListener(MouseEvent.CLICK,onProfile);
			profile.buttonMode= true;
			
			var rect:Rectangle = profile.getBounds(profile);
			profile.addChild(loader);
			loader.opaqueBackground = 0xFFFFFF;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,
				function(e:Event):void {
					loader.mask = profile.getChildAt(0);
					loader.content.scaleX = loader.content.scaleY = Math.max(rect.width/loader.content.width,rect.height/loader.content.height);
					loader.x = Math.floor(-loader.content.width/2+rect.width/2);
					loader.y = Math.floor(-loader.content.height/2+rect.height/2);
					storeImage();
				});
			
//			followUp.addEventListener(MouseEvent.CLICK,onFollowUp);
			admin.addEventListener(MouseEvent.CLICK,onSwitchAdminMode);
			preview.addEventListener(MouseEvent.CLICK,onSwitchAdminMode);
			left.addEventListener(MouseEvent.CLICK,onPage);
			right.addEventListener(MouseEvent.CLICK,onPage);
			up.addEventListener(MouseEvent.CLICK,onScrollAnswer);
			down.addEventListener(MouseEvent.CLICK,onScrollAnswer);
				
//			setImage("https://www.google.com/images/srpr/logo11w.png");
		}
		
		private function storeImage():void {
			if(binaryStore[dialog.profileImage]) {
				delete binaryStore[dialog.profileImage];
			}
			
			var bitmapData:BitmapData = new BitmapData(100,100,true,0);
			bitmapData.draw(profile,new Matrix(2,0,0,2),null,null,null,true);
			var bytes:ByteArray = PNGEncoder.encode(bitmapData);
			bitmapData.dispose();
			var md5:String = MD5.hashBytes(bytes);
			binaryStore[md5] = bytes;
			dialog.profileImage = md5;
			
			trace(Base64.encode(bytes).length);
		}
		
		private function onProfile(e:MouseEvent):void {
			file = new FileReference();
			file.browse([new FileFilter("Images","*.jpeg; *.jpg;*.gif;*.png")]);
			file.addEventListener(Event.SELECT,onSelect);
			
		}
		
		private function onSelect(e:Event):void {
			file.addEventListener(Event.COMPLETE,onLoadImage);
			file.load();
			
		}
		
		private function onLoadImage(e:Event):void {
			var data:ByteArray= file.data;
			loader.loadBytes(data);
		}
		
		private function onBack(e:MouseEvent):void {
			beep2.play();
			dialog.dialogID = history.pop();
			refresh();
		}
		
		private function onScrollAnswer(e:MouseEvent):void {
			var answerIndex:int = dialog.answerIndex?dialog.answerIndex:0;
			dialog.answerIndex = answerIndex+ (e.currentTarget==up?-1:1);
			refresh();
		}
		
		private function onPage(e:MouseEvent):void {
			beep2.play();
			var direction:int = e.currentTarget==left?-1:1;
			var index:int = findDialogIndex(dialogID);
			var newDlg:Object = dialog.dialog[index+direction];
			if(newDlg) {
				dialogID = newDlg.id;
				delete dialog.answerIndex;
				refresh();
			}
		}
		
		private function get desaturationFilter():ColorMatrixFilter {
			var matrix:Array= new Array();
				
			matrix = matrix.concat([1, 1, 1, 0, 0]); // red
			matrix = matrix.concat([1, 1, 1, 0, 0]); // green
			matrix = matrix.concat([1, 1, 1, 0, 0]); // blue
			matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				
			return new ColorMatrixFilter(matrix);
		}
		
		private function onSwitchAdminMode(e:MouseEvent):void {
			beep.play();
			dialog.mode = e.currentTarget==admin ? "admin" : "preview";
			refresh();
		}
		
		public function get dialogID():String {
			return dialog.dialogID ? dialog.dialogID : dialog.dialog.length ? dialog.dialog[0].id : null;
		}
		
		public function set dialogID(value:String):void {
			history.push(dialogID);
			dialog.dialogID = value;
		}
		
		private function onInfo(e:MouseEvent):void {
			infoPopup.visible = !infoPopup.visible;
			infoPopup.tf.text = JSON.stringify(dialog,null,'\t');
		}
		
		private function getIndex(name:String):int {
			var index:int = 0;
			switch(name) {
				case "answer1":
					index = 0;
					break;
				case "answer2":
					index = 1;
					break;
				case "answer3":
					index = 2;
					break;
				case "answer4":
					index = 3;
					break;
			}
			return index;
		}
		
		private function onDelete(e:MouseEvent):void {
			var answerClip:MovieClip = (e.currentTarget.parent) as MovieClip;
			var obj:Object = findDialog(dialogID);
			var index:int = getIndex(answerClip.name);
			
			var answerToDelete:Object = obj.answers[index];
			
			obj.answers.splice(index,1);

			refresh();
		}
		
		private function onItem(e:MouseEvent):void {
			var answerClip:MovieClip = (e.currentTarget.parent) as MovieClip;
			var obj:Object = findDialog(dialogID);
			var index:int = getIndex(answerClip.name);
			promptItem(index);
		}
		
		private function onEditChunk(e:MouseEvent):void {
			var answerClip:MovieClip = (e.currentTarget.parent) as MovieClip;
			var obj:Object = findDialog(dialogID);
			var index:int = getIndex(answerClip.name);

			editAnswer(index);

//			dialog.editingAnswer = index+1;
			
			refresh();
		}
		
		private function onEdit(e:MouseEvent):void {
			if(dialog.mode=="admin") {
				findDialog(dialogID).edit = true;
				refresh();
			}
		}
		
		private function nextAvailableDialogID():String {
			var hash:Object = {};
			for each(var obj:Object in dialog.dialog) {
				hash[obj.id] = true;
			}
			for(var i:int=1;hash[i];i++) {
			}
			var id:String = i.toString();
			return id;
		}
		
		private function onSelectDialog(e:TextEvent):void {
			var selectDialogPopup:MovieClip = (e.currentTarget) as MovieClip;
			var index:int = dialog.answerSelected;
			var destination:String = null;
			var newDialog:Boolean = e.text=="[new]";
			if(newDialog) {
				destination = nextAvailableDialogID();
				dialog.dialog.push({id:destination,text:"",edit:true});
				
				delete dialog.selectedAnswer;
				delete dialog.popup;
			}
			else {
				destination = e.text;
			}
			var obj:Object = findDialog(dialogID);
			var answer:Object = obj.answers[index];
			answer.next = destination;
			if(newDialog) {
				dialogID = destination;
				
			}
			refresh();
		}
		
		private function onKeyMain(e:KeyboardEvent):void {
			var obj:Object = findDialog(dialogID);
			if(e.keyCode==Keyboard.ENTER) {
				obj.text = (e.currentTarget as TextField).text;
				delete obj.edit;
				refresh();
			}
			else if(e.keyCode==Keyboard.ESCAPE) {
				delete obj.edit;
				refresh();
			}
		}
				
		private function onKey(e:KeyboardEvent):void {
			
			var answerClip:MovieClip = (e.currentTarget.parent) as MovieClip;
			if(e.keyCode==Keyboard.ENTER) {
				var obj:Object = findDialog(dialogID);
				var index:int = dialog.editingAnswer-1;

				obj.answers[index].text = (e.currentTarget as TextField).text;
				delete dialog.editingAnswer;
				refresh();
			}
			else if(e.keyCode==Keyboard.ESCAPE) {
				delete dialog.editingAnswer;
				refresh();
			}
		}
		
		private function onAddAnswer(e:MouseEvent):void {
			var obj:Object = findDialog(dialogID);
			if(!obj.answers) {
				obj.answers = [];
			}
			
			obj.answers.push({});
			dialog.editingAnswer = obj.answers.length;
			refresh();
		}
		
/*		private function onFollowUp(e:MouseEvent):void {
			var obj:Object = findDialog(dialogID);
			if(!obj.answers) {
				obj.answers = [];
			}
			var nextID:String = nextAvailableDialogID();
			dialog.dialog.push({id:nextID,text:"",edit:true});
			
			var dID:String = dialogID;
			undoStack.push(
				function():void {
					var obj:Object = findDialog(dID);
					obj.answers.pop();
					dialog.dialog.pop();
					dialogID = dID;
				}
			);
			
			obj.answers.push({text:"...",next:nextID});
			dialogID = nextID;
			refresh();
		}
		*/
		
		private function onMouse(e:MouseEvent):void {

			
			var answerClip:MovieClip = (e.currentTarget.parent) as MovieClip;
			var index:int = getIndex(answerClip.name);
			var obj:Object = findDialog(dialogID);
			var answer:Object = obj.answers?obj.answers[index]:null;
			
			if(!dialog.editingAnswer) {
				switch(e.type) {
					case MouseEvent.ROLL_OUT:
						answerClip.tf.textColor = answer && answer.next ? 0x0066FF : 0xFF0000;
						break;
					case MouseEvent.ROLL_OVER:
						answerClip.tf.textColor = 0xFFFFFF;
						break;
					case MouseEvent.MOUSE_DOWN:
						beep2.play();
						answerClip.tf.textColor = 0xFFFF00;
						break;
					case MouseEvent.MOUSE_UP:
						answerClip.tf.textColor = 0xFFFFFF;
						if(answer && answer.next) {
							delete dialog.answerIndex;
							dialogID = answer.next;
							refresh();
						}
						else if(!answer) {
							if(dialog.mode=="admin")
								createAnswer(index);
						}
						else {
							if(dialog.mode=="admin")
								editAnswer(index);
						}
						break;
				}
			}
		}
		
		public function promptItem(index:int):void {
			dialog.popup = "defineInventoryInteraction";
			dialog.answerSelected = index;
			refresh();
		}
		
		public function promptNext(index:int):void {
			dialog.popup = "selectDestination";
			dialog.answerSelected = index;
			refresh();
		}
		
		public function createAnswer(index:int):void {
			var obj:Object = findDialog(dialogID);
			if(!obj.answers) {
				obj.answers = [];
			}
			var answer:Object = obj.answers[index];
			obj.answers.push({});
			dialog.popup = "createAnswer";
			dialog.answerSelected = index;
			dialog.editingAnswer = index+1;
			
			refresh();
		}
		
		public function editAnswer(index:int):void {
			var obj:Object = findDialog(dialogID);
			var answer:Object = obj.answers[index];
			dialog.popup = "createAnswer";
			dialog.answerSelected = index;
			
			refresh();
		}
		
		public function showCreateAnswerDialog():void {
			if(dialog.popup=="createAnswer") {
				var obj:Object = findDialog(dialogID);
				var index:int = dialog.answerSelected;
				var answer:Object = obj.answers[index];
				answerPopup.visible = true;
				
				var htmlEntries:Array = [];
				
				answerPopup.response.text = answer.text ? answer.text : "";
				
				for (var i:int = 0;i<dialog.dialog.length;i++) {
					var o:Object = dialog.dialog[i];
					
					htmlEntries.push((answer.next==o.id?">":" ") + "  " + o.id +". "+ "<font color='"+(answer.next==o.id?"#FF0000":"#000000")+"'><a href='event:"+dialog.dialog[i].id+"'>"+dialog.dialog[i].text+"</a></font>");
				}
				htmlEntries.push("   "+ nextAvailableDialogID() +". <font color='#0066FF'><a href='event:[new]'>Create response</a></font>");
				
				answerPopup.tf.htmlText = htmlEntries.join("\n");
				
				var editing:Boolean = dialog.editingAnswer==index+1;
				
				if(editing) {
					stage.focus = answerPopup.response;
					answerPopup.response.textColor = 0;
					answerPopup.response.border = true;
					answerPopup.response.background = true;
					answerPopup.response.backgroundColor = 0xFFFFFF;
					answerPopup.response.setSelection(answerPopup.response.length,answerPopup.response.length);
				}
				else {
					answerPopup.response.textColor = 0xFFFFFF;
					answerPopup.response.border = false;
					answerPopup.response.background  =false;					
					stage.focus = null;
				}
				
				setEnabled(answerPopup.loseBox,!editing);
				setEnabled(answerPopup.receiveBox,!editing);
				setEnabled(answerPopup.tf,!editing);
				setEnabled(answerPopup.up,!editing);
				setEnabled(answerPopup.down,!editing);
				setEnabled(answerPopup.label,!editing);
				
				
				answerPopup.cancelButton.addEventListener(MouseEvent.CLICK,closeDialog);
				answerPopup.addEventListener(TextEvent.LINK,onSelectDialog);
				answerPopup.response.addEventListener(KeyboardEvent.KEY_DOWN,onKey);
				answerPopup.response.addEventListener(MouseEvent.MOUSE_DOWN,onEditAnswer);
				answerPopup.response.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,onFocusOut);
			}
			else if(answerPopup.visible) {
				answerPopup.visible = false;
				answerPopup.cancelButton.removeEventListener(MouseEvent.CLICK,closeDialog);
				answerPopup.removeEventListener(TextEvent.LINK,onSelectDialog);
				answerPopup.response.removeEventListener(KeyboardEvent.KEY_DOWN,onKey);
				answerPopup.response.removeEventListener(MouseEvent.MOUSE_DOWN,onEditAnswer);
				answerPopup.response.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,onFocusOut);
			}
		}
		
		private function onFocusOut(e:FocusEvent):void {
			var obj:Object = findDialog(dialogID);
			delete dialog.editingAnswer;
			delete obj.edit;
			refresh();
		}
		
		private function onEditAnswer(e:Event):void {
			if(!dialog.editingAnswer) {
				var obj:Object = findDialog(dialogID);
				var index:int = dialog.answerSelected;
				dialog.editingAnswer = index+1;
				refresh();
			}
		}
		
		public function closeDialog(e:Event):void {
			if(e.type==MouseEvent.CLICK) {
				var popup:String = dialog.popup;
				var editingAnswer:int = dialog.editingAnswer?dialog.editingAnswer:0;
				var answerSelected:int = dialog.answerSelected;
				var emptyText:Boolean = answerPopup.response.text=="";
				delete dialog.popup;
				delete dialog.editingAnswer;
				delete dialog.answerSelected;
				if(emptyText) {
					var obj:Object = findDialog(dialogID);
					obj.answers.pop();
					if(!obj.answers.length) {
						delete obj.answers;
					}
				}
				refresh();
			}
		}
		
		public function setEnabled(control:InteractiveObject,enabled:Boolean):void {
			control.alpha = enabled?1:.3;
			control.mouseEnabled = enabled;
			if(control is DisplayObjectContainer) {
				(control as DisplayObjectContainer).mouseChildren = enabled;
			}
		}

		

		public function showItemDialog():void {
			if(dialog.popup=="defineInventoryInteraction") {
				var obj:Object = findDialog(dialogID);
				var index:int = dialog.answerSelected;
				var answer:Object = obj.answers[index];
				selectItemPopup.visible = true;
				selectItemPopup.response.text = answer.text;
//				stage.addEventListener(KeyboardEvent.KEY_DOWN,optionCancel);
//				selectItemPopup.cancelButton.addEventListener(MouseEvent.CLICK,optionCancel);
			}
			else if(selectItemPopup.visible) {
				selectItemPopup.visible = false;
//				stage.removeEventListener(KeyboardEvent.KEY_DOWN,optionCancel);
//				selectItemPopup.cancelButton.removeEventListener(MouseEvent.CLICK,optionCancel);
			}
		}
		
		private function findDialog(id:String):Object {
			var index:int = findDialogIndex(id);
			return index<0?null:dialog.dialog[index];
		}
		
		private function findDialogIndex(id:String):int {
			for(var i:int=0;i<dialog.dialog.length;i++) {
				if(dialog.dialog[i].id==id) {
					return i;
				}
			}
			return -1;
		}
		
		public function initialize(dialog:Object):void {
			this.dialog = dialog;
			if(!dialog.dialogID) {
				dialog.dialogID = dialogID;
			}
			refresh();
		}
		
		public function setImage(url:String):void {
			loader.load(new URLRequest(url));
		}
		
		public function refresh():void {
			for(i;i<NUM_ANSWERS;i++) {
				this["answer"+(i+1)].visible = false;
			}
			
			if(dialog) {
				if(!dialogID)
					dialogID = dialog.dialog[0].id;
				page.text = dialogID;
				var chunk:Object = findDialog(dialogID);
				if(chunk) {
					tf.text = chunk.text;
					if(chunk.edit) {
						tf.textColor = 0;
						tf.type = TextFieldType.INPUT;
						tf.border = true;
						tf.background = true;
						tf.backgroundColor = 0xFFFFFF;
						tf.selectable = true;
						stage.focus = tf;
						tf.setSelection(tf.length,tf.length);
					}
					else {
						tf.textColor = 0xFFFFFF;
						tf.type = TextFieldType.DYNAMIC;
						tf.selectable = false;
						tf.border = false;
						tf.background = false;
					}
				}
				addAnswer.visible = dialog.mode=="admin" && !dialog.editingAnswer;
				followUp.visible = dialog.mode=="admin" && !dialog.editingAnswer;
				admin.visible = dialog.mode && dialog.mode != "admin";
				preview.visible = dialog.mode && dialog.mode != "preview";
				backButton.visible = dialog.mode=="admin" && history.length;
				
				info.visible = dialog.mode=="admin";
				edit.visible = dialog.mode=="admin";

				var allAnswers:Array = (chunk.answers?chunk.answers:[]).concat(dialog.editingAnswer || dialog.mode!="admin"?[]:[{text:"<create a reply>", placeholder:true}]);
				
				for(var i:int=0;i<Math.min(NUM_ANSWERS,allAnswers.length);i++) {
					var answer:Object = allAnswers[i+(dialog.answerIndex?dialog.answerIndex:0)];
					var editingThisAnswer:Boolean = dialog.editingAnswer==i+1 && dialog.mode=="admin";
					var answerClip:MovieClip = this["answer"+(i+1)];
					answerClip.visible = true;
					answerClip.edit.visible = dialog.mode=="admin" && !dialog.editingAnswer && !answer.placeholder;
					answerClip.del.visible = dialog.mode=="admin" && !dialog.editingAnswer && !answer.placeholder;
					//answerClip.item.visible = dialog.mode=="admin" && !dialog.editingAnswer && !answer.placeholder;
					//answerClip.item.filters = answer.item ? [] : [desaturationFilter];
					answerClip.tf.text = (answer.text?answer.text:"") + (dialog.mode=="admin" && !answer.placeholder && !editingThisAnswer?" -> "+(answer.next?answer.next:""):"");
					if(!editingThisAnswer) {
						answerClip.tf.type = TextFieldType.DYNAMIC;
						answerClip.tf.border = false;
						answerClip.tf.background = true;
						answerClip.tf.backgroundColor = 0x999999;
					}
					else {
						answerClip.tf.type = TextFieldType.INPUT;
						answerClip.tf.border = true;
						answerClip.tf.background = true;
						answerClip.tf.backgroundColor = 0xFFFFFF;
						answerClip.tf.setSelection(answerClip.tf.length,answerClip.tf.length);
						stage.focus = answerClip.tf;
					}
					answerClip.tf.textColor = answer.next? 0x0066FF : 0xFF0000;
				}
				addAnswer.visible &&= allAnswers.length<NUM_ANSWERS;
				up.visible = dialog.answerIndex;
				down.visible = (dialog.answerIndex?dialog.answerIndex:0) + (NUM_ANSWERS) < allAnswers.length;
				
				var dlgIndex:int = findDialogIndex(dialogID);
				left.visible = dialog.mode=="admin" && dlgIndex>0;
				right.visible = dialog.mode=="admin" && dlgIndex<dialog.dialog.length-1;
				page.visible = dialog.mode=="admin";
			}
			showItemDialog();
			showCreateAnswerDialog();
		}
	}
	
}
