// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@/stories/support/form/field/defaultArgTypes'

export default {
  title: 'Form/Field/Inputs/Text',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    maxlength: {
      name: 'maxlength',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    minlength: {
      name: 'maxlength',
      type: { name: 'number', required: false },
      desciption: '',
      table: {
        type: { summary: 'number' },
      },
      control: {
        type: 'number',
      },
    },
    placeholder: {
      name: 'placeholder',
      type: { name: 'text', required: false },
      desciption: '',
      table: {
        type: { summary: 'text' },
      },
      control: {
        type: 'text',
      },
    },
  },
  parameters: {
    docs: {
      description: {
        component: '[FormKit Built-In - Text](https://formkit.com/inputs/text)',
      },
    },
  },
}

const Template: Story = (args) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="text" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  label: 'Title',
  name: 'text',
}
