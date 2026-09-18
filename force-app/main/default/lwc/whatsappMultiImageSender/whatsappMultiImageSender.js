import { LightningElement, api, track, wire } from 'lwc';
import createPublicLinks from '@salesforce/apex/WhatsappMultiImageSenderController.createPublicLinksFromVersions';
import getLibraries from '@salesforce/apex/ImageFileController.getLibraries';
import getImagesByLibrary from '@salesforce/apex/ImageFileController.getImagesByLibrary';
import processSelectedImages from '@salesforce/apex/ImageFileController.processSelectedImages';


export default class WhatsappMultiImageSender extends LightningElement {

    isVisible = false;



    @api recordId;
    @api customerName;
    @api phoneNumber;
    @api businessNumber;
    acceptableFileTypes = ['.jpeg', '.jpg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.svg'];
    imagesC;
    @track images = [];
    @track selectedImageIds = [];
    error;

    @track isModalOpen = false;
    @track modalImageUrl = '';
        @track isLoading = false;



    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }


    get buttonLabel() {
        return this.isVisible ? 'My Computer' : 'Salesforce FIle';
    }

    toggleDiv() {
        this.isVisible = !this.isVisible;
    }
 
    handleUploadFinished(event) {

        console.log('recordId==>', this.recordId);
        console.log('recordId==>', this.customerName);
        console.log('recordId==>', this.phoneNumber);
        console.log('recordId==>', this.businessNumber);
        const uploadedFiles = event.detail.files;
        console.log('Uploaded ContentDocument IDs:', JSON.stringify(uploadedFiles));
        const docIds = uploadedFiles.map(file => file.contentVersionId);

        console.log('Uploaded ContentDocument IDs:', JSON.stringify(docIds));

        this.images = uploadedFiles.map(file => ({
            id: file.contentVersionId,
            name: file.Title,
            url: `/sfc/servlet.shepherd/version/download/${file.contentVersionId}`,
            selected: false
        }));

        // createPublicLinks({
        //     contentVersionIds: docIds, customerName: this.customerName, phoneNumber: this.phoneNumber,
        //     businessNumber: this.businessNumber
        // })
        //     .then(urls => {
        //         console.log('Public Download URLs:', urls);
        //     })
        //     .catch(error => {
        //         console.error('Error creating public URLs:', error);
        //     });
    }



    @track libraryOptions = [];
    @track selectedLibraryId = '';
    @track images = [];
    @track selectedImageIds = [];
    error;

    @wire(getLibraries)
    wiredLibraries({ error, data }) {
        if (data) {
            this.libraryOptions = data.map(lib => ({
                label: lib.Name,
                value: lib.Id
            }));
        } else if (error) {
            this.error = error;
            console.error('Error loading libraries', error);
        }
    }

    handleLibraryChange(event) {
        this.selectedLibraryId = event.detail.value;
        this.fetchImages(this.selectedLibraryId);
    }

    fetchImages(libraryId) {
        getImagesByLibrary({ libraryId })
            .then(data => {
                this.images = data.map(file => ({
                    id: file.Id,
                    name: file.Title,
                    url: `/sfc/servlet.shepherd/version/download/${file.Id}`,
                    selected: false
                }));
                this.selectedImageIds = [];
            })
            .catch(error => {
                this.error = error;
                console.error('Error loading images', error);
            });
    }

    handleCheckboxChange(event) {
        const imgId = event.target.dataset.id;
        const isChecked = event.target.checked;

        if (isChecked) {
            if (!this.selectedImageIds.includes(imgId)) {
                this.selectedImageIds.push(imgId);
            }
        } else {
            this.selectedImageIds = this.selectedImageIds.filter(id => id !== imgId);
        }
    }

    handleSubmit() {
        if (this.selectedImageIds.length > 0) {
        this.isLoading = true;

            processSelectedImages({ selectedImageIds: this.selectedImageIds , customerName: this.customerName, customerNumber: this.phoneNumber,
            businessNumber: this.businessNumber})
                .then((result) => {
            this.isLoading = false;
            this.closeModal();
            this.selectedImageIds='';
                
                })
                .catch(error => {
                    console.error('Error sending image IDs', error);
                });
        } else {
            alert('Please select at least one image.');
        }
    }

    selectAllImages() {
        this.selectedImageIds = [];

        this.images = this.images.map(img => {
            this.selectedImageIds.push(img.id);
            return { ...img, selected: true };
        });

        const checkboxes = this.template.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => {
            cb.checked = true;
        });
    }
}