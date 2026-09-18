import { LightningElement, track } from 'lwc';
import getAssetLibraries from '@salesforce/apex/AssetUploaderController.getAssetLibraries';
import uploadImageToLibrary from '@salesforce/apex/AssetUploaderController.uploadImageToLibrary';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isUserAllowed from '@salesforce/apex/AssetUploaderController.isUserAllowed';

export default class AssetUploader extends LightningElement {
    @track libraryOptions = [];
    selectedLibrary = '';
    filesToUpload = [];
    uploadedCount = 0;
    uploadedFileIds = [];
    uploading = false;
    isUploadVisible = false;
   @track isLoading = false;
   isAllowed= false;

    connectedCallback() {
          isUserAllowed()
        .then(result => {
            this.isAllowed = result;
        });

        getAssetLibraries()
            .then(result => {
                this.libraryOptions = result.map(lib => ({
                    label: lib.Name,
                    value: lib.Id
                }));
            })
            .catch(error => console.error('Error loading libraries:', error));
    }

    handleLibraryChange(event) {
        this.selectedLibrary = event.target.value;
        this.isUploadVisible = !!this.selectedLibrary;
    }

    handleFilesChange(event) {
        const selectedFiles = Array.from(event.target.files);
        if (selectedFiles.length > 100) {
            this.showToast('Error', 'You can upload a maximum of 50 images.', 'error');
            this.filesToUpload = [];
            return;
        }
        this.filesToUpload = selectedFiles;
    }

    get isUploadDisabled() {
        return !this.selectedLibrary || this.filesToUpload.length === 0;
    }

   async uploadFiles() {
    this.uploading = true;
    this.uploadedCount = 0;
    this.uploadedFileIds = [];
this.isLoading = true;
    try {
        for (const file of this.filesToUpload) {
            try {
                const base64 = await this.readFileAsBase64(file);
                const result = await uploadImageToLibrary({
                    base64,
                    fileName: file.name,
                    libraryId: this.selectedLibrary
                });
                this.uploadedFileIds.push(result);
                this.uploadedCount++;
            } catch (error) {
                console.error(`Failed to upload ${file.name}:`, error);
                this.showToast('Error', `Failed to upload ${file.name}. ${error.body?.message || error.message}`, 'error');
            }
        }

        if (this.uploadedCount > 0) {
            this.showToast('Success', `Uploaded ${this.uploadedCount} file(s) successfully.`, 'success');
        } else {
            this.showToast('Info', 'No files were uploaded successfully.', 'info');
        }
    } catch (outerError) {
        console.error('Unexpected error during upload process:', outerError);
        this.showToast('Error', 'Unexpected error during upload.', 'error');
    } finally {
        this.uploading = false;
        this.resetState();
        this.isLoading = false;

    }
}



    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }




    resetState() {
    this.filesToUpload = [];
    this.uploadedCount = 0;
    this.uploadedFileIds = [];
    this.uploading = false;
    this.isUploadVisible = false;
    this.selectedLibrary = '';

    // Clear file input field
    const fileInput = this.template.querySelector('input[type="file"]');
    if (fileInput) {
        fileInput.value = null;
    }
}

}