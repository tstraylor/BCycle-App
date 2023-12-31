//
//  AddBCycleViewController.m
//  BCycle
//
//  Created by Thomas Traylor on 11/25/16.
//  Copyright © 2016 Thomas Traylor. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AddBCycleViewController.h"
#import "BCycleStation.h"
#import "BCycleServices.h"

@interface AddBCycleViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *streetTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityTextField;
@property (weak, nonatomic) IBOutlet UITextField *stateTextField;
@property (weak, nonatomic) IBOutlet UITextField *zipTextField;
@property (weak, nonatomic) IBOutlet UITextField *docksTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButtonItem;

@property (strong, nonatomic) UITextField *activeTextField;

@end

@implementation AddBCycleViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.nameTextField.delegate = self;
    self.streetTextField.delegate = self;
    self.cityTextField.delegate = self;
    self.zipTextField.delegate = self;
    self.docksTextField.delegate = self;
    
    // disable the save button until they enter something
    self.saveButtonItem.enabled = NO;

    // set up the scrollable area for moving the test fields
    // up when the keyboard is presented
    CGSize scrollArea = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height+400);
    self.scrollView.contentSize = scrollArea;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(hideKeyboard)];
    [self.scrollView addGestureRecognizer:tapGesture];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    self.nameTextField.text = self.currentPlacemark.name;
    if (self.currentPlacemark.subThoroughfare != nil && self.currentPlacemark.thoroughfare != nil) {
        self.streetTextField.text = [NSString stringWithFormat:@"%@ %@", self.currentPlacemark.subThoroughfare, self.currentPlacemark.thoroughfare];
    }
    else {
        self.streetTextField.text = nil;
    }
    self.cityTextField.text = self.currentPlacemark.locality;
    self.stateTextField.text = self.currentPlacemark.administrativeArea;
    self.zipTextField.text = self.currentPlacemark.postalCode;
    if(self.nameTextField.text.length && self.streetTextField.text.length &&
       self.streetTextField.text.length && self.stateTextField.text.length &&
       self.zipTextField.text.length && self.docksTextField.text.length)
        self.saveButtonItem.enabled = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Keyboard Management

-(void)hideKeyboard {
    
    [self.activeTextField resignFirstResponder];
    [self.view endEditing:YES];
}

- (void)keyboardWasShown:(NSNotification*)notification {
    
    // get the size of the keyboard, so we can move the textview up to keep the
    // keyboard from hiding the test input.
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeTextField.frame animated:YES];
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    self.activeTextField = nil;
    if(self.nameTextField.text.length && self.streetTextField.text.length &&
       self.streetTextField.text.length && self.stateTextField.text.length &&
       self.zipTextField.text.length && self.docksTextField.text.length)
        self.saveButtonItem.enabled = YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBActions Bar Button Items pressed

- (IBAction)saveButtonPressed:(UIBarButtonItem *)sender {
    
    // disable the save button since it was already pressed
    self.saveButtonItem.enabled = NO;
    BCycleStation *bcycle = [[BCycleStation alloc] init];
    [bcycle setLocation: self.currentPlacemark.location.coordinate];
    [bcycle setName: self.nameTextField.text];
    [bcycle setStreet: self.streetTextField.text];
    [bcycle setCity: self.cityTextField.text];
    [bcycle setState: self.stateTextField.text];
    [bcycle setZip: self.zipTextField.text];
    [bcycle setDocks: [NSNumber numberWithLong:[self.docksTextField.text integerValue]]];

    BCycleServices *bcycleService = [[BCycleServices alloc] init];
    
    [bcycleService createStation:bcycle WithCompletion:^(NSDictionary *item, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            NSString *msg;
            NSString *title;
            if(error == nil) {
                
                title = @"Your submission was successful.";
                msg = @"Your BCycle Station location has been saved.";
            }
            else {
                
                title = @"Your submission failed.";
                msg = @"Something went wrong in the clouds. Please re-submit the location.";
            }
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:msg
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
